# FORMAL SPEC ENGLISH

Status: constructed, not machine-checked.

Plain-English paraphrase of `fvk/fits-identifier-spec.k`:

- `FITS-NONEXT-EMPTY-ARGS`: with no file object, a non-FITS filepath, and no
  positional object arguments, the FITS identifier returns `False`.
- `FITS-SUFFIX-PATH`: with no file object and a FITS-suffix filepath, the FITS
  identifier returns `True`.
- `FITS-FILEOBJ-SIGNATURE`: with a file object whose signature is FITS, the
  FITS identifier returns `True`.
- `FITS-FILEOBJ-NONSIGNATURE`: with a file object whose signature is not FITS,
  the FITS identifier returns `False`, even if another category would otherwise
  match.
- `FITS-HDU-ARG`: with no file object, no FITS-suffix path, and a first
  positional argument that is a FITS HDU object, the FITS identifier returns
  `True`.
- `FITS-NONHDU-ARG`: with no file object, no FITS-suffix path, and a first
  positional argument that is not a FITS HDU object, the FITS identifier returns
  `False`.
