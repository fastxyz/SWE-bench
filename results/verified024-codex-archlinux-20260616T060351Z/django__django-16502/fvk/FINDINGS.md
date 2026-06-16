# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F1: Pre-V1 runserver bug, addressed by V1 and retained in V2

Input: a `HEAD /` request served by `runserver` with a response body such as
`b"<html>..."`.

Observed in the issue: headers followed by the HTML response body.

Expected from E1: headers only; no response body bytes returned.

V1 addressed this at `ServerHandler.write()`, `sendfile()`, and
`finish_response()`. The FVK audit confirms this is the right layer because E2
assigns body removal to the server.

Related obligations: PO1, PO2, PO3, PO4, PO5, PO8.

## F2: V1 abnormal-exit cleanup was too narrow, fixed in V2

Input: a `HEAD` response iterator or finish step that exits abnormally with a
`BaseException` subclass outside `Exception` after `ServerHandler.finish_response`
has taken over response completion.

Observed in V1 by static inspection: the custom `finish_response()` used
`except Exception`, so its explicit `self.result.close()` cleanup was not
guaranteed on all abnormal exits.

Expected from E7 and the obligation created by overriding inherited completion:
the result close path should be preserved for abnormal exits handled by the
custom finisher.

V2 changes the handler to use `except BaseException:` in that cleanup block,
then re-raise.

Related obligations: PO6.

## F3: V1 correctly covered sendfile/file-wrapper bypasses

Input: a `HEAD` request whose response is exposed through `wsgi.file_wrapper` or
a handler subclass with a sendfile optimization.

Observed risk before V1: suppressing only `write()` would leave an alternate
body-producing path.

Expected from E1 and E6: no optimized file body is returned for `HEAD`.

V1's `sendfile()` override returns `False` for `HEAD`, forcing the header-only
path and leaving body output unchanged.

Related obligations: PO4, PO5.

## F4: Conditional middleware HEAD handling is required, retained in V2

Input: a `HEAD` request with a non-streaming response body available to
middleware and conditional request headers such as `If-None-Match`.

Observed before V1: `ConditionalGetMiddleware` returned immediately for
non-`GET` methods and carried a comment saying a `HEAD` body was unavailable.

Expected from E4 and E5: `HEAD` may be conditionally processed like `GET`
because the body is present until final server stripping.

V1 changed the gate to `request.method in ("GET", "HEAD")` and updated the
comments/docstring. V2 keeps that change.

Related obligations: PO7.

## F5: Constructed proof remains un-machine-checked

Input: any of the K claims in `fvk/django-head-spec.k`.

Observed in this environment: no K toolchain execution is allowed.

Expected by the FVK honesty gate: artifacts must be labeled "constructed, not
machine-checked"; test removal must not be recommended as unconditional.

V2 keeps all verification claims as constructed reasoning only and does not
modify tests.

Related obligations: PO9.
