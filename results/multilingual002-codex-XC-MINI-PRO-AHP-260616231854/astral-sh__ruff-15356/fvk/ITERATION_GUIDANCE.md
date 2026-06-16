# ITERATION GUIDANCE

Status: next-step guidance from the FVK audit.

## Code Decision

Keep V1 unchanged. Findings F-01 through F-04 and proof obligations PO-01 through PO-07 support the current source edit. No audit finding identifies a missing source change.

## Recommended Future Tests

Do not edit tests in this benchmark session. For a normal development branch, add or keep tests covering:

- No `E252` for keyword arguments inside a no-type-parameter type alias value: `type MyType = Annotated[..., Field(min_length=4)]`.
- `E252` remains active for actual type-parameter defaults such as `type Alias[T=int] = int`.
- Nested brackets inside type-parameter defaults do not prematurely end type-parameter tracking.
- Annotated function parameter defaults still receive `E252` where appropriate.

## Recommended Future Verification

Run the recorded K commands in a real K environment. Treat the proof as constructed until `kprove` returns `#Top`.

## Open Risk

The reduced formal model does not prove end-to-end Ruff behavior: tokenization, logical-line construction, diagnostic rendering, fix application, and CLI output remain integration concerns. That does not block the V1 source decision because the issue-local root cause and frame conditions are discharged at the state-machine level.
