# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbols

### `DocstringSignatureMixin._find_signature(encoding=None)`

Public compatibility status: preserved.

The method name and call signature are unchanged.  It still returns the first
`(args, retann)` pair or `None`.  Its side effect now strips all leading
signature lines, which is the intended behavior for overloaded docstrings.

Consumers found in source:

- `DocstringStripSignatureMixin.format_signature()`

Risk and disposition:

- Risk: strip-only documenters could re-emit a cached plural signature.
- Disposition: no plural cache write occurs in `_find_signature()`, so delegated
  plural parsing sees the stripped body and emits nothing.

### New helper `DocstringSignatureMixin._find_signatures()`

Public compatibility status: additive internal helper.

No source callsites outside `DocstringSignatureMixin` were found.  It is used to
avoid changing `_find_signature()`'s return shape.

### `DocstringSignatureMixin.format_signature(**kwargs)`

Public compatibility status: preserved shape.

The method still returns a string.  Multiple signatures are encoded with the
existing newline protocol already consumed by `Documenter.add_directive_header()`
and already used by singledispatch documenters.

### `Documenter.add_directive_header(sig)`

Public compatibility status: unchanged.

No source change is required because it already splits `sig` on newline and
emits one directive header line per signature line.

## Producer/consumer shape

Producer: `format_signature()` now may return a newline-separated signature
string for overloaded docstrings.

Consumer: `add_directive_header()` already treats newline-separated signatures
as multiple directive signatures.

Compatibility result: pass.
