# Constructed Proof

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## Claims Proved

The formal claims are in `fvk/quantity-dtype-spec.k`, over the minimal fragment
semantics in `fvk/mini-quantity.k`.

The central contract is:

- If no explicit dtype is supplied and the input dtype is inexact, the
  constructor result dtype is the input dtype.
- `float16` is one of the modeled inexact dtypes.
- Non-inexact default coercion, explicit dtype override, `copy=False`, and
  structured dtype behavior are framed unchanged.

## Proof Sketch

1. `UnitBase.__rmul__` is inspected as a public call path. For numeric operands
   without a `unit` attribute, it returns `Quantity(m, self)`. It does not pass
   an explicit dtype, so the reported `np.float16(1) * u.km` reproducer reaches
   the non-`Quantity`, `dtype=None` constructor branch.

2. In `Quantity.__new__`, the non-`Quantity` branch first converts the input to
   a NumPy array without an explicit dtype. For a `np.float16` scalar, the
   resulting `value.dtype` is the input dtype `float16`.

3. V1 changed the default preservation predicate from
   `np.can_cast(np.float32, value.dtype)` to
   `np.issubdtype(value.dtype, np.inexact)`, while retaining the existing
   `value.dtype.fields` exception. Since `float16` is a NumPy inexact dtype,
   the condition that would call `value.astype(float)` is false. The value is
   viewed as a `Quantity` with dtype `float16`.

4. The same predicate replacement appears in the existing-`Quantity` copy
   branch. Therefore copying an inexact dtype quantity without an explicit
   dtype also preserves the dtype.

5. Frame obligations are checked by branch structure:
   explicit `dtype` still bypasses default inference; `copy=False` for an
   existing `Quantity` still returns early; integer, bool, and object dtypes are
   not inexact and still take the float coercion path; structured dtypes still
   satisfy the `value.dtype.fields` exception.

## Matching Logic / K Interpretation

The mini semantics models the observable dtype as the whole result. This is
property-complete for the defect: a passing instance maps to `float16`, while
the reported failing instance maps to `float64`; the abstraction distinguishes
them.

Each K claim is a straight-line reachability claim over `construct(branch,
input_dtype, maybe_explicit_dtype)`. There are no loops or recursive calls, so
no circularity claims are needed.

## Machine Check Commands

These commands are emitted for later checking and were not run:

```sh
kompile fvk/mini-quantity.k --backend haskell
kast --backend haskell fvk/quantity-dtype-spec.k
kprove fvk/quantity-dtype-spec.k
```

Expected machine-check result: `kprove` returns `#Top` for all claims.

## Test Guidance

No tests were edited. No tests should be removed based on this constructed
proof unless the K commands are later run and discharge to `#Top`.

Useful public tests to add in a normal development setting would cover:

- `np.float16(1) * u.km` keeps dtype `np.float16`.
- `u.Quantity(np.array([1], dtype=np.float16), u.km)` keeps dtype
  `np.float16`.
- Copying a `Quantity` with dtype `np.float16` and default `copy=True` keeps
  dtype `np.float16`.
- Existing integer, bool, Decimal object, explicit dtype, and `float32` tests
  continue to pass.

## Residual Risk

The proof is partial with respect to the modeled fragment and constructed only.
It does not verify all of NumPy or Astropy. It verifies the dtype decision
predicate and frames the public behaviors relevant to this issue.
