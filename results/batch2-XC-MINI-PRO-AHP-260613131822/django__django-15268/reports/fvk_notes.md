# FVK audit notes — django__django-15268

## Outcome

**V1 stands, unchanged.** The Formal Verification Kit pass produced a total contract for
`AlterTogetherOptionOperation.reduce`, a soundness lemma for its `True` verdict, and a
termination argument for the optimizer loop. Every behavioural proof obligation
discharged; the only residuals are a non-triggering invariant and a proof-capability
boundary — neither warrants a source edit. This note justifies each decision by tracing it
to [`fvk/FINDINGS.md`](../fvk/FINDINGS.md) and
[`fvk/PROOF_OBLIGATIONS.md`](../fvk/PROOF_OBLIGATIONS.md).

The V1 change under audit is the single method
(`repo/django/db/migrations/operations/models.py`, `AlterTogetherOptionOperation`):

```python
def reduce(self, operation, app_label):
    return super().reduce(operation, app_label) or (
        isinstance(operation, AlterTogetherOptionOperation) and
        self.name_lower == operation.name_lower
    )
```

---

## Decisions, each traced to an obligation/finding

### D1 — Keep the fix as-is (no behavioural change)
- **Why:** The fix's one behavioural delta is REDUCE-COMMUTE-SAMEMODEL — same model,
  different kind now returns `True` instead of `False` (**PO-FIX**). PROOF.md §2 shows
  every *other* `reduce` row is bit-identical to V0 (**PO-COLLAPSE, PO-DIFFMODEL,
  PO-SCOPE**), so the change is surgical.
- **Soundness check that gates the decision:** **PO-COMMUTE** (F2). The `True` verdict
  lets the optimizer reorder an `AlterUniqueTogether` past an `AlterIndexTogether` on the
  same model. I verified this is sound at the source level: `state_forwards` merges a
  single, kind-specific key into the options dict (`state.py:170` —
  `model_state.options = {**model_state.options, **{option_name: value}}`), and the two
  ops use disjoint keys (`unique_together` vs `index_together`); `database_forwards` calls
  `alter_unique_together` vs `alter_index_together`, which manage disjoint DB objects.
  Distinct slots ⇒ updates commute (lemma VC-DISJOINT, PROOF.md §3). The contract holds,
  so the fix is correct and needs no change.

### D2 — Do NOT broaden or narrow the `isinstance(..., AlterTogetherOptionOperation)` gate
- **Why:** **PO-SCOPE** (F3). The gate is exactly what stops the fix from collapsing an
  `AlterFooTogether` across a field operation (`AddField`/`AlterField`) on the same model,
  which would undo the #31503 remove-then-add split. The modelled `reduce(true,_,false,_)
  => barrier` claim (REDUCE-SCOPE) confirms field ops still act as barriers. Narrowing the
  gate to a specific kind pair would be redundant (only two subclasses exist — verified at
  models.py:153/470/538/549); broadening it to all `ModelOptionOperation`s would be
  *unsound* (e.g. two `AlterModelTable`s do not commute). The base-class gate is the
  precise correct scope.

### D3 — Do NOT "harden" the `super().reduce() or (…)` idiom against empty-list shadowing
- **Why:** **PO-NOSHADOW** (F4). I checked the full dispatch chain
  (`ModelOptionOperation.reduce` → `ModelOperation.reduce` → `Operation.reduce`): for an
  `AlterFooTogether` self it can only return a *non-empty* list, `True`, or `False` —
  never `[]`. So the `or` never mis-fires. Rewriting it to an explicit `is not False`
  check would diverge from the identical idiom already used in `ModelOperation.reduce` and
  `RenameModel.reduce`, adding noise to defend against a state that cannot occur. Logged as
  a documented invariant with a re-audit trigger (G2) instead of a code change.

### D4 — Do NOT attempt to "fix" the escalated whole-list soundness
- **Why:** **PO-OPT-SOUND** (F6). Whole-list `optimize` equivalence is an
  `[ESCALATION BOUNDARY]` (list induction + a `ProjectState`/`SchemaEditor` model), a
  proof-capability limit — **not** a code defect. The step-local obligations the fix
  actually relies on (PO-COLLAPSE, PO-COMMUTE) are discharged, and the optimizer's own
  reorder guards already require commutation (PROOF.md §5). There is nothing in the source
  to change; the honest action is to mark the boundary and keep the integration test (D5),
  which I did rather than faking a `[trusted]` discharge.

### D5 — Recommend keeping all tests; remove none
- **Why:** PROOF.md §6 + honesty gate. `test_alter_alter_*` exercise the *separate*
  same-kind collapse path (PO-COLLAPSE) and must be preserved; the issue's interleaved
  scenario is an end-to-end check whose domain is the escalated PO-OPT-SOUND, so it is not
  subsumed. With no machine-checked `#Top` yet, no removal is safe. (Test files are also
  read-only for this task.)

### D6 — Preserve the V1 method placement
- **Why:** purely structural; `reduce` sits as the last method of
  `AlterTogetherOptionOperation`, matching the convention in `CreateModel`/`RenameModel`.
  The audit surfaced no reason to move it. No change.

---

## Why no code was changed

The five `fvk/` artifacts collectively show the V1 fix is **correct** (PO-FIX +
PO-COMMUTE), **minimal and surgical** (PO-COLLAPSE/PO-DIFFMODEL/PO-SCOPE unchanged from
V0), **terminating** (PO-TERM), and **idiomatic** (matches existing `reduce`
overrides and the models.py:153 use of the same base class). The two open items are
tracked, not defects:

| Residual | Obligation | Classification | Action |
|---|---|---|---|
| empty-list `or` shadowing | PO-NOSHADOW (F4) | documented invariant, cannot occur | none (re-audit trigger G2) |
| whole-list `optimize` equivalence | PO-OPT-SOUND (F6) | proof-capability `[ESCALATION BOUNDARY]` | keep integration test; route to papers (G3) |

Changing the source to chase either would be unjustified by the artifacts and would risk
regressing the clean, established idiom. V1 is confirmed.
