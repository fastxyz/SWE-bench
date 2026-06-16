# Iteration Guidance

Status: V1 stands. No additional source changes are justified by the FVK audit.

## Decision

Keep the V1 source patch unchanged.

Rationale:

- F-001 is discharged by PO-1: direct empty constructor names now raise `ValueError`.
- F-002 is discharged by PO-4: empty registration-time name overrides now raise `ValueError` before registration state is mutated.
- F-003 is discharged by PO-6: nested empty name overrides are caught when the nested registration becomes effective through `Blueprint.register`.
- PO-5 and PO-7 show the patch preserves existing behavior for non-empty names and does not change public signatures.

## Rejected Changes

- Do not change the guard to `if not name`; NF-001 has no public-intent support and would alter non-string or otherwise falsy inputs beyond the issue.
- Do not add whitespace stripping; NF-001 only supports the exact empty string.
- Do not add dotted `name=` override validation in this issue; NF-002 identifies it as a separate compatibility question.
- Do not add immediate validation to `Blueprint.register_blueprint`; F-003 and PO-6 show the effective registration path is covered, and the public issue does not require validation at option-recording time.

## Suggested Tests for a Future Test Suite

These are recommendations only; this task forbids modifying tests.

- `Blueprint("", __name__)` raises `ValueError`.
- `app.register_blueprint(Blueprint("bp", __name__), name="")` raises `ValueError`.
- A valid non-empty blueprint name still prefixes endpoints as before.
- A valid blueprint registered with a non-empty `name=` override still works.
- A nested blueprint recorded with `name=""` raises when the parent is registered on an app.

## Residual Risk

The proof is constructed, not machine-checked. It also models only the validation and name-resolution fragment relevant to this issue, not full Python or full Flask routing behavior. That is adequate for deciding whether V1 should stand, but it is not a replacement for the broader Flask test suite.

