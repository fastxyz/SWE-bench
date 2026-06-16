# Public Compatibility Audit

Status: no compatibility blockers found.

## Changed public symbols

None.

The V1 source change did not alter the `loaddata` command-line interface,
method signatures, return type shape, public setting name, exception classes,
or documented fixture search order.

## Public callsites and overrides

The changed expression is inside the cached `fixture_dirs` property. It
normalizes local values from `settings.FIXTURE_DIRS` before the existing
validation checks. No virtual dispatch signature changed, and no caller must
pass a new argument or consume a new return type.

## Compatibility conclusion

Compatibility obligation PO-005 passes. Existing callers that provide strings
continue through the same branch. Existing callers that provide valid
path-like objects continue to work because `os.fspath()` is the standard
path-like conversion and returns the string used by the later `os.path`
operations.
