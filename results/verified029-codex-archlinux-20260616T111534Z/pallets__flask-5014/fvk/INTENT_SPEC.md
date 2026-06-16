# Intent Specification

Intent-only obligations from public evidence:

1. A `Blueprint` must not have the empty string as its name.
2. Attempting to give a blueprint the empty string as its constructor name must raise `ValueError`.
3. Because `register_blueprint(..., name=...)` changes the pre-dotted blueprint name used for endpoint naming, attempting to use `name=""` as an effective registration name must raise `ValueError`.
4. Existing valid non-empty blueprint names must keep working.
5. Existing dotted constructor-name validation must keep working because dots separate blueprint names and endpoint names.
6. Public method signatures and callback protocols should remain unchanged.

Out of scope for this issue:

- Whitespace-only names.
- Non-string values passed despite type annotations.
- Dotted `name=` registration overrides.
- Exact `ValueError` message text.

