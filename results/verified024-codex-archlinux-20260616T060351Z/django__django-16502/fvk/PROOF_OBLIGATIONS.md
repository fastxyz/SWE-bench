# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO1: HEAD write emits no body bytes

For any `HEAD` request and byte chunk length `N >= 0`, `ServerHandler.write()`
must leave the modeled socket body output unchanged.

Evidence: E1, E6. Finding: F1.

Discharge: V2's `write()` branch for `HEAD` performs status/header bookkeeping
and never calls `_write(data)` with body data.

## PO2: Body stripping occurs at the server boundary

The fix must not mutate `HttpResponse.content`, `StreamingHttpResponse`, or
`WSGIHandler` output before middleware has completed.

Evidence: E2, E4. Finding: F1.

Discharge: V2 changes only `ServerHandler` output hooks and
`ConditionalGetMiddleware`'s safe-method gate/comment.

## PO3: Headers are still sent and flushed for HEAD

For `HEAD`, a header-only response must still send and flush headers, because no
body write remains to perform the normal flush.

Evidence: E3. Finding: F1.

Discharge: V2 calls `send_headers()` and `_flush()` in the `HEAD` `write()` path
and flushes after `finish_content()`.

## PO4: sendfile cannot bypass HEAD body suppression

For `HEAD`, any optimized file-send path must not transmit body bytes.

Evidence: E1, E6. Finding: F3.

Discharge: V2 returns `False` from `sendfile()` for `HEAD`, forcing the modeled
header-only finish path.

## PO5: finish_response must not drain full HEAD bodies

For `HEAD`, `finish_response()` should not stream all body chunks to nowhere;
it should establish headers, flush, and close. This avoids hangs or unnecessary
work for streaming responses.

Evidence: E1, E3, E6. Findings: F1, F3.

Discharge: V2 advances at most one chunk from the result, calls `write()` only
for header bookkeeping, calls `finish_content()`, flushes, and closes.

## PO6: Response close semantics are preserved on abnormal exits

When custom `finish_response()` takes over from the inherited implementation,
it must close the result if completion exits abnormally.

Evidence: E7. Finding: F2.

Discharge: V2 changed `except Exception` to `except BaseException:` and
re-raises after closing `self.result` if it has `close`.

## PO7: ConditionalGetMiddleware handles HEAD as a safe conditional method

For `HEAD`, middleware should be able to calculate an ETag for non-streaming
body content and return conditional responses when validators match.

Evidence: E4, E5, E8. Finding: F4.

Discharge: V2 keeps V1's `request.method not in ("GET", "HEAD")` gate and
updated comments/docstring.

## PO8: Non-HEAD behavior is framed

For any non-`HEAD` method, `write()`, `sendfile()`, and `finish_response()` must
delegate to inherited behavior.

Evidence: E2, E6. Finding: F1.

Discharge: V2 immediately delegates to `super()` for non-`HEAD` in all three
overridden methods.

## PO9: Verification honesty and test immutability

Because the environment forbids execution and test edits, proof artifacts must
remain constructed-only and no tests may be modified.

Evidence: task instructions and FVK honesty gate. Finding: F5.

Discharge: no tests, Python, or K tools were run; no test files were modified.
