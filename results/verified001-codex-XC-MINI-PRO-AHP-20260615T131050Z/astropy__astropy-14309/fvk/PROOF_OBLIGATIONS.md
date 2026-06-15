# PROOF OBLIGATIONS

Status: constructed, not machine-checked.

## PO-001: File-object signature branch

If `fileobj is not None`, `is_fits` must:

- save the current file position;
- read the signature bytes;
- restore the original file position;
- return whether the signature equals `FITS_SIGNATURE`;
- avoid consulting `filepath` or `args`.

Trace: E-005. Finding: F-002.

## PO-002: FITS filepath suffix branch

If `fileobj is None`, `filepath is not None`, and the lower-case filepath ends
with one of the existing FITS suffixes, `is_fits` must return `True`.

Trace: E-005, E-007. Finding: F-002.

## PO-003: Non-FITS filepath with empty args

If `fileobj is None`, `filepath is not None`, the filepath does not end with a
FITS suffix, and `args` is empty, `is_fits` must return `False` without reading
`args[0]`.

Trace: E-001, E-002, E-003, E-004. Finding: F-001.

K claim: `FITS-NONEXT-EMPTY-ARGS`.

## PO-004: Positional FITS HDU object fallback

If no earlier file-object or FITS-suffix branch returns, and at least one
positional object argument exists, `is_fits` must return whether `args[0]` is an
instance of `HDUList`, `TableHDU`, `BinTableHDU`, or `GroupsHDU`.

Trace: E-005, E-006. Finding: F-002.

K claims: `FITS-HDU-ARG`, `FITS-NONHDU-ARG`.

## PO-005: Public compatibility

The repair must not change:

- the public `is_fits(origin, filepath, fileobj, *args, **kwargs)` signature;
- the registry `identify_format` call protocol;
- the FITS suffix list;
- the accepted FITS HDU object classes;
- test files.

Trace: E-004, E-006, E-007. Finding: F-003.

## PO-006: Scope control for sibling identifiers

Do not expand this issue into unrelated identifier changes unless public intent
or proof localization shows those functions contribute to the reported failure.

Trace: E-001, E-002, E-003. Finding: F-004.

## PO-007: Honesty gate

All formal proof artifacts and exact K commands must be emitted, but no
`kompile`, `kast`, `kprove`, Python, or test execution may be performed in this
benchmark environment.

Trace: FVK method documentation and task constraints. Finding: F-005.
