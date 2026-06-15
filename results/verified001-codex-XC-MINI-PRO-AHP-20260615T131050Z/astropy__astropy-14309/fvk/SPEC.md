# SPEC: FITS Identifier Empty-Args Safety

Status: constructed, not machine-checked.

## Scope

Target source unit:

- `repo/astropy/io/fits/connect.py::is_fits(origin, filepath, fileobj, *args, **kwargs)`

Integration point:

- `repo/astropy/io/registry/base.py::identify_format(...)`, which calls each
  registered identifier as `identifier(origin, path, fileobj, *args, **kwargs)`.

No loops or recursion are present in the audited source unit.

## Intent Specification

`is_fits` is a predicate used by the I/O registry. For in-domain registry calls:

1. If `fileobj` is present, inspect the file signature and return whether it is
   FITS, while restoring the file position.
2. Otherwise, if `filepath` is present and has a FITS extension, return `True`.
3. Otherwise, if a positional object argument exists, return whether `args[0]`
   is a FITS HDU object accepted by the table FITS connector.
4. Otherwise, return `False`.
5. The empty positional-argument case is in domain. It must not raise
   `IndexError`.

The critical bug-fix case is:

```python
identify_format("write", Table, "bububu.ecsv", None, [], {})
```

For the FITS identifier, this must produce a non-match (`False`) rather than
indexing into an empty `args` tuple.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | `benchmark/PROBLEM.md` | "IndexError: tuple index out of range in identify_format (io.registry)" | The reported registry call must not raise `IndexError`. | Encoded by PO-003 and K claim `FITS-NONEXT-EMPTY-ARGS`. |
| E-002 | `benchmark/PROBLEM.md` | `identify_format("write", Table, "bububu.ecsv", None, [], {})` | Empty `args` is an in-domain registry input for this issue. | Encoded by PO-003. |
| E-003 | `benchmark/PROBLEM.md` | "When `filepath` is a string without a FITS extension, the function was returning None, now it executes `isinstance(args[0], ...)`" | A non-FITS path with no payload object should be a non-match, not an object-indexing attempt. | Encoded by PO-003. |
| E-004 | `repo/astropy/io/registry/base.py` | `args : sequence` in `identify_format` and call shape `identifier(origin, path, fileobj, *args, **kwargs)` | The identifier must tolerate the sequence supplied by the registry, including an empty sequence in the reported direct call. | Encoded by PO-003 and PO-005. |
| E-005 | `repo/astropy/io/fits/connect.py` docstring | "Determine whether `origin` is a FITS file." | The function is a predicate; non-matching inputs return false-like results. | Encoded by PO-001 through PO-004. |
| E-006 | `repo/astropy/io/fits/connect.py` existing imports and read doc | `HDUList`, `TableHDU`, `BinTableHDU`, `GroupsHDU` are accepted FITS objects. | Preserve object-based positive identification when a positional object exists. | Encoded by PO-004. |
| E-007 | `repo/astropy/io/fits/connect.py` existing suffix list | `.fits`, `.fits.gz`, `.fit`, `.fit.gz`, `.fts`, `.fts.gz` | Preserve extension-based positive identification. | Encoded by PO-002. |

## Formal Model Summary

The model in `fvk/mini-fits-identifier.k` abstracts concrete Python values into
the observable categories that determine `is_fits`:

- `PathKind`: no path, FITS-suffix path, non-FITS-suffix path.
- `FileKind`: no file object, file object with FITS signature, file object
  without FITS signature.
- `ArgsKind`: empty positional arguments, first argument is a FITS HDU object,
  or first argument is not a FITS HDU object.

This abstraction is property-complete for the defect because it distinguishes a
passing implementation (`nonFitsPath`, `noFile`, `noArgs` rewrites to `false`)
from the failing pre-fix implementation (the corresponding Python path attempts
`args[0]`).

## Adequacy Round Trip

- Intent item E-001/E-002/E-003 requires no `IndexError` and a FITS non-match
  for a non-FITS filepath with empty args.
- K claim `FITS-NONEXT-EMPTY-ARGS` says
  `isFits(nonFitsPath, noFile, noArgs) => false`.
- The formal English paraphrase is the same obligation: with no file object, a
  non-FITS path, and no positional object, the FITS identifier returns `False`.

No claim is candidate-derived without public intent support. The only behavior
preserved from implementation evidence is the existing positive matching for
FITS file signatures, FITS extensions, and FITS HDU object arguments, all of
which are part of the existing public connector behavior.
