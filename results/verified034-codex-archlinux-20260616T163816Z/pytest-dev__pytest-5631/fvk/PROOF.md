# FVK Proof

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## Claim Proved

For `repo/src/_pytest/compat.py::num_mock_patch_args`, V1 satisfies the spec in
`fvk/SPEC.md`: when mock modules are loaded, the helper returns the cardinality
of patchings whose `attribute_name` is falsey and whose `new` object is
identical to a loaded `DEFAULT` sentinel. Explicit non-sentinel `new=` values,
including array-like objects, are not equality-compared and are not counted.

## Symbolic Proof Sketch

Let `patchings = getattr(function, "patchings", None)`.

Case 1: `not patchings`.

The function returns `0` immediately. This discharges PO-005.

Case 2: `patchings` is truthy and neither `mock` nor `unittest.mock` is loaded.

`mock_modules` contains no loaded module. The `if any(mock_modules)` branch is
not taken, and the function returns `len(patchings)`. V1 did not alter this
branch. This discharges PO-006.

Case 3: `patchings` is truthy and at least one mock module is loaded.

The function builds `sentinels = [m.DEFAULT for m in mock_modules if m is not
None]`. For each patching object `p`, the list-comprehension predicate is:

```python
not p.attribute_name and any(p.new is s for s in sentinels)
```

If `p.attribute_name` is truthy, Python short-circuits the `and` expression and
excludes `p`. This preserves the existing attribute-name filter.

If `p.attribute_name` is falsey, the generator evaluates `p.new is s` for each
sentinel `s`. The `is` operator returns true exactly when both operands are the
same Python object. It does not call equality methods and does not interpret an
equality result as a truth value. Therefore:

- If `p.new` is a loaded `DEFAULT` sentinel, one generator element is true,
  `any(...)` is true, and `p` is included exactly once.
- If `p.new` is any explicit non-sentinel replacement, including an array-like
  object, all generator elements are false, `any(...)` is false, and `p` is
  excluded without invoking equality.

The outer `len([...])` returns the cardinality of exactly those included
patching objects. This discharges PO-001 through PO-004 and PO-007.

## Reported Failure Path

For the issue example, model the relevant patching as
`patch(false, arrayNew)` and the sentinel list as
`[defaultUnittest]`. The constructed K claim in
`fvk/num-mock-patch-args-spec.k` states:

```k
patchCount(ListItem(patch(false, arrayNew)) .List,
           ListItem(defaultUnittest) .List) => 0
```

The V1 source implements the same predicate with Python object identity. The
array-like explicit `new=` value is not identical to the sentinel, so the patch
does not count and no array equality/truth-value operation is reached.

## Machine-Check Commands

These commands are provided for a future environment with K installed. They were
not run here.

```sh
cd fvk
kompile mini-patchcount.k --backend haskell
kast --backend haskell num-mock-patch-args-spec.k
kprove num-mock-patch-args-spec.k
```

Expected machine-check result in a compatible K environment: `#Top` for all
claims.

## Test Guidance

No tests were modified. Because this proof is constructed but not
machine-checked, no existing tests should be removed on the basis of this FVK
run.

Useful future public tests would cover:

- an explicit array-like `new=` object whose equality result cannot be used as a
  boolean;
- a default `@patch(...)` case where `new is DEFAULT` still consumes one mock
  argument;
- an explicit non-sentinel `new=` object with custom `__eq__` to confirm equality
  is not invoked.
