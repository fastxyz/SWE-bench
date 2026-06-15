# FVK Iteration Guidance

Status: V1 stands unchanged.

## Code Decision

No source edit is justified by the FVK findings. Findings F1-F3 are discharged
by proof obligations PO1-PO5. Findings F4-F5 are explicit scope and proof
capability boundaries, not defects in V1.

## Recommended Next Checks

When an execution environment is available, run the normal project tests that
exercise Quantity ufuncs and table Column interaction. Do not remove tests based
on this constructed proof alone.

Add or keep focused tests for:

- unknown unit-bearing duck arrays with different but convertible units;
- unknown unit-bearing duck arrays with same units;
- non-ndarray unit-bearing objects with only `__array__`, confirming delegation
  rather than Quantity coercion;
- Quantity plus table Column, confirming Column compatibility;
- `out` containing an unknown unit-bearing duck output.

## Deferred Formal Work

The full NumPy ufunc dispatch algorithm and Astropy's complete unit conversion
helper suite are outside this mini-model. Formalizing those would require a
larger Python/NumPy semantics and should be treated as an escalation task.

`FunctionQuantity.__array_ufunc__` has a separate unsupported-ufunc policy. If
future public intent asks function quantities to delegate unsupported ufuncs to
other duck arrays, formalize and repair that method separately rather than
folding it into this generic Quantity fix.

## Machine Check Commands

The commands were not run in this no-execution environment:

```sh
cd fvk
kompile mini-ufunc-dispatch.k --backend haskell
kast --backend haskell quantity-ufunc-dispatch-spec.k
kprove quantity-ufunc-dispatch-spec.k
```
