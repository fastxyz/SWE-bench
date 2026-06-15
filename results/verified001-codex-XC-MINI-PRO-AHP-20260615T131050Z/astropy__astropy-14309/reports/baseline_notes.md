# Baseline Notes

## Root cause

`astropy.io.registry.identify_format` calls registered identifier functions with
`origin`, `path`, `fileobj`, and then the caller-supplied positional `args`.
For calls like:

```python
identify_format("write", Table, "bububu.ecsv", None, [], {})
```

the FITS identifier receives an empty `args` tuple. In
`astropy.io.fits.connect.is_fits`, a non-FITS filename does not return from the
filepath extension check, so execution falls through to `args[0]`. With no
positional payload object, that raises `IndexError` instead of simply reporting
that the input is not FITS.

## Changed files

- `repo/astropy/io/fits/connect.py`: guarded the final HDU object-type check so
  it only inspects `args[0]` when at least one positional argument is present.
  This preserves the existing positive matches for FITS file-like objects,
  FITS filename extensions, and FITS HDU objects while making empty-argument
  identification return `False`.

## Assumptions and alternatives

- I assumed the registry is allowed to call identifiers with an empty `args`
  sequence, since `identify_format` accepts `args` as an arbitrary sequence and
  the issue reproducer explicitly passes `[]`.
- I assumed a non-FITS filepath with no extra object should be identified as
  not FITS rather than treated as an error.
- I considered changing `identify_format` to avoid calling identifiers when
  `args` is empty, but rejected that because identifier functions already need
  to handle combinations of `path`, `fileobj`, and object arguments, and a
  registry-level change would alter behavior for all formats.
- I considered changing other identifier functions with similar `args[0]`
  patterns, but rejected that as outside the reported failure. The FITS
  identifier is the one that falls through from an unrecognized filepath to
  `args[0]` for write-format identification.
