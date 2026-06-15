# PUBLIC COMPATIBILITY AUDIT

Status: constructed, not machine-checked.

Changed public symbol:

- `astropy.io.fits.connect.is_fits`

Compatibility checks:

| Item | Status |
| --- | --- |
| Function signature | Unchanged: `is_fits(origin, filepath, fileobj, *args, **kwargs)`. |
| Registry call protocol | Unchanged: `identify_format` still calls identifiers with `origin`, `path`, `fileobj`, expanded `args`, and `kwargs`. |
| Registered format | Unchanged: `io_registry.register_identifier("fits", Table, is_fits)`. |
| FITS suffixes | Unchanged. |
| Accepted HDU object classes | Unchanged. |
| Test files | Unchanged. |

No public callsite or override update is required.
