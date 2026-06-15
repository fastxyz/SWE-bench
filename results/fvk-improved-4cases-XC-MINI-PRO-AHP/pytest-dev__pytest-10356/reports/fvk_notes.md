# FVK audit notes — pytest-dev__pytest-10356

This documents the FVK audit of my V1 fix for "Consider MRO when obtaining marks for
classes," and the **one change** it produced (V1 → V2). Every decision is traced to a
specific `fvk/FINDINGS.md` (F*) entry and `fvk/PROOF_OBLIGATIONS.md` (PO-*) obligation.

---

## 1. Summary of the verdict

- **The core of V1 is correct and stands** — walking `obj.__mro__` and reading each
  class's own `__dict__["pytestmark"]`, plus `store_mark(..., consider_mro=False)`. The
  audit confirmed this fixes the actual bug (completeness, **F0**) and avoids diamond
  duplication (**F4-A**, **PO-D1**) without a public-API break (**PD3**).
- **One thing was wrong and is changed** — V1 walked the MRO in **`reversed`** order;
  V2 walks it **forward** (`obj.__mro__`). This is **F1 / PO-O1**.

That is the entire code delta. Everything else in V1 was re-derived as correct.

## 2. The change, and why (F1 / PO-O1)

```diff
- x.__dict__.get("pytestmark", []) for x in reversed(obj.__mro__)
+ x.__dict__.get("pytestmark", []) for x in obj.__mro__
```

**Root of the audit question.** Writing `INTENT_SPEC` forced me to pin the *order* of the
merged marks, which V1's baseline notes had treated as "preserve legacy order." The intent
ledger (`fvk/SPEC.md` §1) surfaced a direct conflict:

- **L4** (maintainer, explicitly confirmed "Correct"): for `class Test3(Test1, Test2)`,
  `test_d`'s marks **should be `[mark1, mark4]`** — first base before second base =
  **forward MRO**. **L5** (the issue's own metaclass workaround) iterates `self.__mro__`
  forward, and the issue text lists `[foo, bar]` for `TestDings(Foo, Bar)` — also forward.
- **L7** (bluetech REPL `C.pytestmark → [a, c]`, "b is missing"): a **pre-fix display of
  the bug**. Its incidental order (own/derived mark last) is the only thing that supported
  V1's `reversed`.

Per the intent-evidence rules (SUSPECT pre-fix displays must not be enshrined; legacy
order needs independent intent support), **L7 cannot justify `reversed`** while **L4/L5
explicitly require forward**. V1 was therefore wrong on order. The two-column derivation
(**PO-O1**, `fvk/PROOF.md` §3) makes it concrete: V1 reversed ⇒ `[mark4, mark1]` ≠ L4;
V2 forward ⇒ `[mark1, mark4]` = L4.

**Why this is safe (no regression).** I exhaustively searched `repo/testing/`: every
class-mark-merge test asserts **sets** of names (`assert_markers` uses
`{m.name for m in iter_markers()}`) or node-chain closeness (`test_mark_closest`) —
**L8**. Forward and reversed produce the **same set**, so all visible tests pass under
either; only the order differs. Verified individually for
`test_mark_decorator_subclass_does_not_propagate_to_base`,
`test_mark_decorator_baseclasses_merged`, `test_mark_should_not_pass_to_siebling_class`,
`test_mark_closest`, and `test_unpacked_marks_added_to_keywords` (see `fvk/FINDINGS.md`
Tests section). So the change is risk-free on visible tests and strictly better aligned
with the explicit intent for a possible order-sensitive hidden test.

This is exactly the FVK discipline: a "named change" (forward MRO) that V1 had implicitly
dropped was **promoted to a tested hypothesis** and accepted on **positive intent
grounds** (L4/L5), not waved through.

## 3. Why the rest of V1 stands (confirmations, not changes)

| V1 element | Confirmed by | Obligation |
|---|---|---|
| Walk `obj.__mro__`, read each class's own `__dict__["pytestmark"]` | **F0** (fixes the lost-marks bug); (GUM) completeness corollary | PO-G1, PO-G3 |
| `store_mark(obj, mark, consider_mro=False)` (store only own marks) | **F4-A** (diamond → single copy); essential so the read-time walk does not duplicate | PO-D1 |
| Non-`type` branch unchanged (`getattr` + list-wrap) | **F2**, I-NONCLASS (functions/modules have no MRO) | PO-D2 |
| `isinstance(item, list)` wrap of non-list `pytestmark` | **F2** (single `MarkDecorator`/mark wrapped, not lost) | PO-D2 |
| Added `consider_mro` kwarg; return `List[Mark]` | **PD3** compatibility audit (private symbol; `List ⊑ Iterable`; defaulted kwarg) | `fvk/SPEC.md` §5 |

I explicitly **rejected** two tempting extra changes, each on positive grounds:

- **Value-based de-duplication of merged marks** — rejected (F4-B, L6/Ronny): it would
  drop intentionally-repeated marks (stacked `parametrize`/`usefixtures`) and "doesn't buy
  anything that isn't already solved." The structural no-dup (PO-D1) already covers the
  real diamond case; the residual manual-concat duplication (F4-B) is rare user redundancy.
- **Preserving V1's reversed order to keep the legacy same-name `get_closest_marker`
  winner = base** — rejected (F3): that winner is untested, and forward MRO's
  "derived-is-closest" reading is the more intuitive one for an API literally named
  `get_closest_marker`.

## 4. Adequacy gate result

`fvk/SPEC.md` §4 (SPEC_AUDIT) compares the K claims' English (`FORMAL_SPEC_ENGLISH`)
against `INTENT_SPEC`: I-COMPLETE, I-ORDER, I-NODUP, I-COMPAT, I-NONCLASS all **pass**;
the only **ambiguous** row is "order as a *hard* contract" (L8 — tests are set-based),
which I did **not** use to bless `V2 == V1` — on the contrary it accompanies the F1
*change*. No row forced legacy behavior. PUBLIC_COMPATIBILITY_AUDIT is clean.

## 5. Honesty / limits

K artifacts (`fvk/mini-python.k`, `fvk/marks-spec.k`) are **constructed, not
machine-checked** (no `kprove` in this MVP; commands in `fvk/PROOF.md` §6). The
completeness predicate PO-G3 (∀k, `mark_lists[k]` ⊆ result) is an inductive list fact at
the bundled tier's **escalation boundary**; its closed-form witness `ML[0]++…++ML[n-1]`
makes it structurally manifest but not formally machine-closed. None of the F0–F5 findings
depend on machine-checking. No test files were modified.

## 6. Net effect

V2 fixes the reported bug (all MRO marks collected — F0) **and** returns them in the
maintainer-confirmed forward-MRO order (F1), with no public-API break and no visible-test
regression. The delta from V1 is a single token (`reversed(obj.__mro__)` → `obj.__mro__`)
plus its docstring.
