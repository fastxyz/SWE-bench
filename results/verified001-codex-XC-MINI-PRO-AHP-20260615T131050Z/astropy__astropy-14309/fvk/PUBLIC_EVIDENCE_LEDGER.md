# PUBLIC EVIDENCE LEDGER

This standalone ledger mirrors the entries in `fvk/SPEC.md`.

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E-001 | `benchmark/PROBLEM.md` | "IndexError: tuple index out of range in identify_format (io.registry)" | Remove the `IndexError` for the reported registry identification path. |
| E-002 | `benchmark/PROBLEM.md` | `identify_format("write", Table, "bububu.ecsv", None, [], {})` | Treat empty positional args as in-domain for this direct registry call. |
| E-003 | `benchmark/PROBLEM.md` | "When `filepath` is a string without a FITS extension..." | Non-FITS path with no object argument is a non-match. |
| E-004 | `repo/astropy/io/registry/base.py` | `identifier(origin, path, fileobj, *args, **kwargs)` | Identifier functions receive expanded positional args and must match that protocol. |
| E-005 | `repo/astropy/io/fits/connect.py` | `is_fits` predicate docstring | Return a truth value indicating FITS match or non-match. |
| E-006 | `repo/astropy/io/fits/connect.py` | imported/accepted FITS HDU classes | Preserve object-based FITS matching. |
| E-007 | `repo/astropy/io/fits/connect.py` | existing FITS suffix tuple | Preserve extension-based FITS matching. |
