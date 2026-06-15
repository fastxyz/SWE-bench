# FVK Spec

Status: constructed, not machine-checked.

## Scope

Audit target: `repo/astropy/units/core.py`, `UnrecognizedUnit.__eq__` as fixed
in V1, plus the dependent `UnrecognizedUnit.__ne__`.

No loops or recursion are present in the target method, so the formal proof has
no circularity obligation. It is a branch-complete case split over the abstract
outcome of `Unit(other, parse_strict='silent')`.

## Public Intent Ledger

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E-001 | prompt | "x == None  # Should be False" | `UnrecognizedUnit == None` returns `False`. |
| E-002 | prompt hint | "`==` should never fail" | Known unit-conversion rejection failures do not escape equality. |
| E-003 | source compatibility | `UnitBase.__eq__` catches `(ValueError, UnitsError, TypeError)` and returns `False`. | Use the same conversion-failure policy for unknown units. |
| E-004 | public tests | `test_unknown_unit3` checks same/different unknown unit equality. | Preserve name-based equality. |
| E-005 | public tests | `test_unknown_unit3` expects direct `u.Unit(None)` to raise `TypeError`. | Do not alter direct constructor behavior. |
| E-006 | public tests | `test_compare_with_none` checks normal units compare with `None` without raising. | Align unknown unit equality with normal unit equality. |

The standalone ledger is mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

## Model

The mini semantics in `fvk/mini-python-unit-eq.k` abstracts
`Unit(other, parse_strict='silent')` into one of these conversion outcomes:

- `ok(unrec(T))`: conversion produced an `UnrecognizedUnit` named `T`;
- `ok(recognized)`: conversion produced a recognized unit value;
- `raises(valueError)`, `raises(unitsError)`, or `raises(typeError)`:
  conversion rejected the target in a known unit-conversion way.

The model intentionally preserves the property under audit: whether equality
returns `True`, returns `False`, or lets a known conversion exception escape.

## Contract

For any `self` that is an `UnrecognizedUnit` with name `S`:

- If conversion of `other` produces `UnrecognizedUnit(T)`, then
  `self == other` returns `S == T`.
- If conversion of `other` produces a recognized unit value, then
  `self == other` returns `False`.
- If conversion of `other` raises `ValueError`, `UnitsError`, or `TypeError`,
  then `self == other` returns `False` and no exception escapes.
- `self != other` returns the complement of `self == other`.
- Direct `Unit(None)` construction remains outside this equality catch and can
  still raise `TypeError`.

## Formal Core

K artifacts:

- `fvk/mini-python-unit-eq.k`
- `fvk/unrecognized-unit-eq-spec.k`

Exact commands to machine-check later, not executed in this audit:

```sh
cd fvk
kompile mini-python-unit-eq.k --backend haskell
kast --backend haskell unrecognized-unit-eq-spec.k
kprove unrecognized-unit-eq-spec.k
```

Expected machine-check result if the mini semantics and claims parse as written:
`#Top` for all claims. This audit did not run K tooling.

## Adequacy

The formal-English paraphrase in `fvk/FORMAL_SPEC_ENGLISH.md` matches the
intent obligations in `fvk/INTENT_SPEC.md`; `fvk/SPEC_AUDIT.md` marks each
claim as pass. `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` found no signature,
constructor, operator, or callsite compatibility issue.
