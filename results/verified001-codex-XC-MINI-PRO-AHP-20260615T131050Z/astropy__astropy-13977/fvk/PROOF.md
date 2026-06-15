# FVK Proof

Status: constructed, not machine-checked. The commands below were not run.

## Artifacts

- `fvk/mini-ufunc-dispatch.k`
- `fvk/quantity-ufunc-dispatch-spec.k`

Machine-check commands to run later:

```sh
cd fvk
kompile mini-ufunc-dispatch.k --backend haskell
kast --backend haskell quantity-ufunc-dispatch-spec.k
kprove quantity-ufunc-dispatch-spec.k
```

Expected machine result after the environment is available: `#Top` for the
claims in `quantity-ufunc-dispatch-spec.k`.

## What Is Proved

For the modeled dispatch gate of `Quantity.__array_ufunc__`:

1. Any unknown non-ndarray object with `unit` in the inputs or outputs reaches
   `NOT_IMPLEMENTED`.
2. Any list containing only `Quantity`, `numpy.ndarray`, `None`, or non-unit
   plain objects reaches `PROCEED`.
3. Therefore converter lookup and converter application are unreachable on the
   duck-array path that caused the reported `ValueError`.

## Proof Sketch

Let `scan = concat(inputs, outputs)`.

Base case: `scan = .Objs`. By the `guard(.Objs)` rule, the dispatch decision is
`PROCEED`. This satisfies PO3 and PO4 because there is no unsupported unit
object.

Accepted-head cases: if the head is `Q`, `ND`, `NONE`, or `OTHER_PLAIN`, the
guard rewrites to `guard(tail)`. By induction on `tail`, the result is
`NOT_IMPLEMENTED` iff `tail` contains `OTHER_UNIT`; otherwise it is `PROCEED`.
This discharges preservation for recognized Quantity/ndarray/Column paths and
plain non-unit paths.

Unsupported-head case: if the head is `OTHER_UNIT`, the guard rewrites directly
to `NOT_IMPLEMENTED`. No recursive scan or abstract converter transition occurs.
This discharges the core issue obligation: the duck array is delegated before
`converters_and_unit()` or converter application.

Concatenation case: `quantityArrayUfunc(inputs, outputs)` first rewrites to
`guard(concat(inputs, outputs))`. By structural induction over `inputs`, every
input appears before every output in `scan`, and no element is dropped. Applying
the guard proof over `scan` discharges PO1.

## Adequacy Gate

The English claims match the intent-only obligations:

- I1 maps to claims C1 and C3, and to PO2 and PO5.
- I2 maps to C2 and C4, and to PO4.
- I3 maps to C2 and PO3.
- I4 maps to C1/C2 over `concat(inputs, outputs)` and PO1.
- I5 is recorded as out of scope in Finding F4.

The model is property-complete for this bug because it preserves the exact
observable distinction the issue requires: `OTHER_UNIT -> NOT_IMPLEMENTED`
instead of `OTHER_UNIT -> converter`.

## Test Guidance

No test files were modified. Because the proof is not machine-checked, no test
removal is recommended.

Useful tests to keep or add in a normal development environment:

- `Quantity(1, m) + DuckArray(Quantity(1, mm))` delegates and succeeds through
  the duck array.
- `Quantity(1, mm) + DuckArray(Quantity(1, mm))` still delegates and succeeds.
- `Quantity` interacting with table `Column` still uses the existing path.
- `out=(DuckArray(...),)` delegates rather than attempting `check_output()`.

## Residual Risk

The proof is partial and scoped. It does not prove the full NumPy dispatch
algorithm, all Astropy ufunc helpers, or termination/performance properties. It
does prove that V1's early guard satisfies the public intent slice that caused
the reported `ValueError`.
