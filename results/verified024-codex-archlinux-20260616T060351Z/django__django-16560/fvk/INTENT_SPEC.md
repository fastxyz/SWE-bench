# Intent Spec

Status: constructed, not machine-checked.

## Required behavior from public intent

I-1. `BaseConstraint` must expose a way to customize the `code` attribute of
`ValidationError` instances raised during constraint validation, analogous to
the existing `violation_error_message` customization.

I-2. The public hint names the parameter `violation_error_code`, so the
constructor/API obligation is to add that parameter rather than another spelling.

I-3. Custom codes must be preserved across the constraint lifecycle where custom
messages are preserved: construction, migration deconstruction, cloning, equality
comparison, and developer-facing representation.

I-4. Concrete built-in constraints that raise `ValidationError` with
`get_violation_error_message()` must pass the stored custom code to
`ValidationError`.

I-5. `UniqueConstraint` with `fields` and without `condition` has a documented
legacy validation branch using `unique_error_message()` instead of
`violation_error_message`; the new code parameter is not required to override
that branch unless the documented message behavior also changes.

I-6. Existing callers that omit the new parameter must keep the old observable
behavior: default code remains `None`, default messages remain unchanged, and
existing constructor calls remain valid.

