# Public Compatibility Audit

Changed public symbols: none.

Changed private helper:

- `matplotlib.dates._wrap_in_tex(text)` keeps the same name, signature, input
  type expectation, and return type.

Public call sites inspected:

- `DateFormatter.__call__`: unchanged signature; TeX branch gets improved helper
  output.
- `AutoDateFormatter.__call__`: unchanged signature; string formats continue to
  delegate to `DateFormatter`.
- `ConciseDateFormatter.format_ticks`: unchanged signature; labels and offset
  strings continue to call `_wrap_in_tex` when `_usetex` is true.

Subclass/override compatibility:

- No public virtual method signature was changed.
- No call now passes a new keyword or argument shape to overrides.

Producer/consumer compatibility:

- Output remains a string intended for Matplotlib text rendering.
- Existing alphabetic splitting is preserved for month/day names.

Result: pass. No compatibility-driven source change is required.
