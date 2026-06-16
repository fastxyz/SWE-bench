# Intent Specification

This file records public intent before accepting implementation behavior as a
specification.

1. The Morse mapping for digit `"1"` must be `.----`, not `----`.
2. Default `encode_morse("1")` must return `.----`.
3. Default `decode_morse(".----")` must return `"1"`.
4. Because default encoding is derived from the default decode table, the source
   decode table should be the single source of truth.
5. The surrounding Morse digit family should remain the standard digit family.
6. Public API shape and existing non-digit Morse behavior should be preserved.

