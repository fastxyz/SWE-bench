# PROOF

Status: constructed, not machine-checked.

## Claim Summary

The proof covers `is_fits(origin, filepath, fileobj, *args, **kwargs)` as a
partial-correctness predicate over the registry inputs relevant to the issue.
There are no loops, so no circularity or termination argument is required.

Formal core:

- Semantics: `fvk/mini-fits-identifier.k`
- Claims: `fvk/fits-identifier-spec.k`

## Constructed Proof

### PO-001: File-object branch

When `fileobj is not None`, the first `if` branch executes. The code stores the
current position, reads the signature, seeks back to the stored position, and
returns `sig == FITS_SIGNATURE`. The branch returns immediately, so neither the
filepath suffix logic nor the positional-argument fallback can affect the
result. This discharges the file-object claims `FITS-FILEOBJ-SIGNATURE` and
`FITS-FILEOBJ-NONSIGNATURE`.

### PO-002: FITS filepath suffix branch

When `fileobj is None` and `filepath is not None`, execution enters the filepath
branch. If `filepath.lower().endswith((... FITS suffixes ...))` is true, the
function returns `True` immediately. V1 did not edit this branch. This
discharges claim `FITS-SUFFIX-PATH`.

### PO-003: Non-FITS filepath with empty args

For the issue input, the FITS identifier receives:

- `fileobj is None`;
- `filepath == "bububu.ecsv"`;
- `args == ()` after `identify_format` expands the caller's empty `[]`.

Symbolic execution:

1. The file-object branch is skipped because `fileobj is None`.
2. The filepath branch is entered because `filepath is not None`.
3. The FITS suffix check is false for `"bububu.ecsv"`.
4. Control reaches the final return.
5. V1 evaluates `len(args) > 0` first. Since `len(()) == 0`, the conjunction is
   false and Python short-circuits before evaluating `args[0]`.
6. The function returns `False`.

This discharges claim `FITS-NONEXT-EMPTY-ARGS` and resolves F-001.

### PO-004: Positional FITS HDU object fallback

When no file object is present and no FITS suffix matched, V1 still evaluates
the same `isinstance(args[0], (HDUList, TableHDU, BinTableHDU, GroupsHDU))`
expression whenever `len(args) > 0`. Therefore a first positional FITS HDU
object still returns `True`, and a non-HDU first positional object returns
`False`. This discharges `FITS-HDU-ARG` and `FITS-NONHDU-ARG`.

### PO-005 and PO-006: Compatibility and scope

V1 changes only the final return expression in `is_fits`; it does not change the
function signature, registry call shape, suffix list, accepted HDU classes, or
test files. Static localization from the reported stack trace points to
`is_fits`, so no sibling identifier changes are justified by this FVK pass.

## Exact Machine-Check Commands

These commands are emitted for a later environment with K installed. They were
not run here.

```sh
kompile fvk/mini-fits-identifier.k --backend haskell
kast --backend haskell fvk/fits-identifier-spec.k
kprove fvk/fits-identifier-spec.k
```

Expected result after machine checking: `#Top` for all claims.

## Residual Risk

- Constructed, not machine-checked: the K artifacts and proof were written but
  not executed.
- The mini-K model abstracts Python string suffix checks and Python class
  membership into categories. This abstraction is adequate for the issue because
  it preserves the defect axis: empty `args` versus a present first object.
- No termination proof is needed because the audited function has no loop or
  recursion.
- No test removal is recommended. Keep all tests unless the K proof is later
  machine-checked and maintainers separately decide which in-domain tests are
  redundant.
