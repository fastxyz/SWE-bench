# FVK Spec

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## Scope

The audited unit is the default dtype decision in
`repo/astropy/units/quantity.py::Quantity.__new__`, plus the public unit
multiplication path in `repo/astropy/units/core.py::UnitBase.__rmul__` that
delegates numeric operands to `Quantity(m, unit)`.

This scope is property-complete for the reported issue because the observable
defect is the result dtype after construction. The formal model preserves the
dtype axis (`float16` versus `float64`) and abstracts away value arithmetic and
unit algebra that do not influence the default dtype predicate on the reported
path.

## Public Intent Ledger

See `fvk/PUBLIC_EVIDENCE_LEDGER.md` for the standalone ledger. Critical entries:

- E-001: the reported `np.float16(1) * u.km` path must not produce
  `dtype('float64')`.
- E-002: existing examples show other floating dtypes are preserved.
- E-003: the public hint says every inexact type should be allowed.
- E-004: explicit dtype and non-inexact default behavior are preserved frame
  conditions.
- E-005: `UnitBase.__rmul__` reaches `Quantity(m, self)` for numeric operands.
- E-006: V1 changes no public signatures or dispatch protocol.

## Intended Contract

For `Quantity.__new__(value, unit, dtype=None, copy=True, ...)`:

1. If the input value has an inexact NumPy dtype, the default constructor
   preserves that dtype.
2. `np.float16` is an inexact dtype, so `np.float16(1) * u.km` produces a
   `Quantity` with dtype `float16`.
3. Existing structured dtype preservation through `value.dtype.fields` remains
   unchanged.
4. Existing explicit `dtype` behavior remains unchanged.
5. Existing default conversion of integer, bool, and numeric object dtype values
   to Python float / NumPy `float64` remains unchanged.

## Formal Core

The machine-checkable core is:

- `fvk/mini-quantity.k`: a minimal K semantics for the dtype decision fragment.
- `fvk/quantity-dtype-spec.k`: K reachability claims for the contract above.

Exact commands to machine-check later, not run in this session:

```sh
kompile fvk/mini-quantity.k --backend haskell
kast --backend haskell fvk/quantity-dtype-spec.k
kprove fvk/quantity-dtype-spec.k
```

Expected result after machine-checking: `kprove` discharges all claims to
`#Top`.

## Adequacy

The adequacy round trip is recorded in:

- `fvk/INTENT_SPEC.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

All formal-English obligations pass against the public intent. The pre-fix
display that produced `float64` is classified as SUSPECT legacy behavior, not
an expected result.
