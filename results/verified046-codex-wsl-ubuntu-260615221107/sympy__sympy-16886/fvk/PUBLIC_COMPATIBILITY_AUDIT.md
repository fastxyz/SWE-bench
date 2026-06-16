# Public Compatibility Audit

## Changed public symbols

None. V1 changes a dictionary key literal inside `morse_char`; it does not change
function names, function signatures, module exports, argument defaults, or return
types.

## Public callsites and imports

- `repo/sympy/crypto/__init__.py` exports `encode_morse` and `decode_morse`.
  Export shape is unchanged.
- `repo/sympy/crypto/tests/test_crypto.py` imports and calls `encode_morse` and
  `decode_morse`. The existing calls do not depend on the legacy digit-1 mapping.
- `repo/doc/src/modules/crypto.rst` uses autodoc for both functions. No doc
  signature or directive changes are needed.

## Verdict

Pass. No compatibility issue blocks keeping V1 unchanged.

