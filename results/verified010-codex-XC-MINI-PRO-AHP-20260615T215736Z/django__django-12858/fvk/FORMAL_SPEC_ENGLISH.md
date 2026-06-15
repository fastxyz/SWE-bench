# FORMAL_SPEC_ENGLISH.md

Status: constructed, not machine-checked.

## Claim Paraphrases

- `REPORTED-CASE`: If a path resolves `supply`, then `product`, then `parent`, and the final segment `isnull` does not resolve as a field but is registered as a lookup on the `parent` field, the validator returns `ok`.
- `FINAL-LOOKUP-VALID`: For any previously resolved field, a final unresolved path segment is valid when it is registered as a lookup on that field and is not a transform.
- `TRANSFORM-STILL-VALID`: For any previously resolved field, an unresolved segment registered as a transform remains valid.
- `NONFINAL-LOOKUP-INVALID`: A lookup that is not also a transform does not validate an unresolved segment when more path segments remain.

## Frame Conditions

- Leading `-` handling is unchanged by the patch.
- Skipping expressions and `?` ordering is unchanged by the patch.
- Error ID and error-message template for invalid ordering remain unchanged.
