# FINDINGS.md — django__django-15268

Plain-language findings from formalizing the V1 fix. Each is `input → observed vs
expected`. Benefit-2 findings do **not** depend on machine-checking. "Constructed, not
machine-checked."

---

## Findings from `/formalize`

### F1 — Same-kind collapse is preserved (positive)
- **Input:** `[AlterUniqueTogether(m,{a,b}), AlterUniqueTogether(m,{a,c})]`.
- **Observed (V1):** optimizes to `[AlterUniqueTogether(m,{a,c})]`. `super().reduce()`
  returns `[operation]`; the new `or` clause is short-circuited (truthy list).
- **Expected:** the later op wins. ✅ Matches. The fix is additive — the existing
  same-class reduction (and its tests `test_alter_alter_unique_model` /
  `test_alter_alter_index_model`) is untouched. (PO-COLLAPSE)

### F2 — The `commute` (`True`) verdict is sound only because the two options are disjoint (positive, the key invariant)
- **Input:** `AlterUniqueTogether(m, U)` and `AlterIndexTogether(m, I)` on the same model.
- **Observed (V1):** `reduce` returns `True`, so the optimizer may reorder them.
- **Expected:** reordering must not change the migration. It doesn't: `state_forwards`
  writes only `unique_together` resp. `index_together` (a single, disjoint dict key —
  `state.py:170`), and `database_forwards` touches disjoint DB objects (unique
  constraints vs. indexes). So `apply(U);apply(I) ≡ apply(I);apply(U)`. ✅ (PO-COMMUTE)
- **Note:** this disjointness is the load-bearing fact of the whole fix. If a future
  `AlterFooTogether` subclass were added whose `state_forwards`/`database_forwards`
  touched a *shared* option/object, the blanket `True` would become unsound. Today only
  `AlterUniqueTogether` and `AlterIndexTogether` exist (verified), and they are disjoint.

### F3 — The fix does NOT regress #31503 (positive, scope check)
- **Input:** `[AlterUniqueTogether(m,∅), AlterField(m, 'a', …), AlterUniqueTogether(m,{('a','b')})]`
  — a unique constraint dropped, the field it covers altered, then re-added.
- **Observed (V1):** `AlterUniqueTogether.reduce(AlterField)` returns `False`
  (`AlterField` is not an `AlterTogetherOptionOperation`, so the new clause is skipped and
  `super().reduce()` = `False` stands). The optimizer does **not** collapse across the
  field alteration. ✅
- **Expected:** the remove/add split introduced by #31503 must survive so the field can
  be altered while unreferenced. ✅ The fix is correctly gated on
  `isinstance(operation, AlterTogetherOptionOperation)`. (PO-SCOPE)

### F4 — Latent (non-triggering) shadowing risk in the `or` idiom
- **Input (hypothetical):** any chain where `super().reduce()` returns an **empty list**
  `[]`.
- **Observed:** Python's `or` treats `[]` as falsy, so `[] or (… True)` would return
  `True` — silently converting a "delete both operations" verdict into a "reorder"
  verdict.
- **Expected vs reality:** for an `AlterFooTogether` self, `super().reduce()` provably
  never returns `[]` (it returns a 1-element list, `True`, or `False` — see PO-NOSHADOW).
  So the bug is **unreachable today**. **Classification:** documented invariant, *not* a
  bug. **Decision:** no code change — the `super().reduce() or (…)` idiom is exactly the
  established pattern in `ModelOperation.reduce` and `RenameModel.reduce`; hardening it
  (e.g. `result = super().reduce(...); return result if result is not False else (…)`)
  would diverge from the codebase idiom for a case that cannot arise. Re-audit this if any
  `AlterFooTogether`-chain `reduce` is ever made to return `[]`.

### F5 — Spec was clean to write (no bug signal)
A total, case-complete contract for `reduce` (§3 of SPEC.md) and a length variant for
the optimizer loop were both straightforward — no awkward case split, no missing
precondition, no “impossible” corner. Per the kit's "spec-difficulty = bug signal"
heuristic, the *absence* of difficulty is positive evidence the fix is well-formed.

---

## Proof-derived findings from `/verify`

### F6 — `optimize` whole-list soundness is an escalation boundary, not a gap in the fix
- **Evidence:** PO-OPT-SOUND. Proving "the optimized list has the same net effect as the
  input, for *every* input list" requires induction over arbitrary operation lists and a
  model of `ProjectState`/`SchemaEditor` — recursive-data + relational reasoning beyond
  the bundled arithmetic/map tier.
- **Classification:** proof-capability gap `[ESCALATION BOUNDARY]`, **not** a code bug.
  The per-reduction-step obligations (PO-COLLAPSE, PO-COMMUTE) *are* discharged, and the
  optimizer's own reorder guards already require commutation — so the fix introduces no
  new step that is unsound. Marked honestly rather than admitted as `[trusted]`.

### F7 — Termination is robust to the change
- **Evidence:** OPT-TERM. The fix adds only a `True` verdict; `True` never lengthens the
  list, so the length variant still strictly decreases on every changing pass. No new
  non-termination risk. (PO-TERM)

### F8 — No new precondition required
- **Evidence:** the `reduce` contract is total (defined for all operand combinations); no
  `requires` had to be invented to make a claim go through. Contrast the `sum` example,
  where the proof *forced* `n ≥ 0`. Here the only side condition (COMMUTE's disjointness)
  is **discharged automatically** by the existing `isinstance`/`name_lower` gates rather
  than imposed as an unchecked assumption.

---

## Verdict

No code defect found. Every behavioural obligation (PO-COLLAPSE, PO-FIX, PO-DIFFMODEL,
PO-SCOPE, PO-COMMUTE, PO-TERM) is **DISCHARGED**; the only residuals are a non-triggering
invariant (F4/PO-NOSHADOW, documented) and a proof-capability boundary (F6/PO-OPT-SOUND,
escalated). **V1 stands.**
