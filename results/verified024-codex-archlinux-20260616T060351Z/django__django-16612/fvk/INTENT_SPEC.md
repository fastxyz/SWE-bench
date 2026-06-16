# INTENT SPEC

Status: intent-only. Current implementation behavior is not used as expected
behavior unless independently supported by public evidence.

## Required Behavior

1. When the admin catch-all view performs an `APPEND_SLASH` redirect, it must
   preserve the request query string.
2. The slash must be appended to the path component before the query component.
3. For the public example, `/admin/auth/foo?id=123` must redirect to
   `/admin/auth/foo/?id=123`.
4. The redirect applies only under the existing admin catch-all gates:
   `APPEND_SLASH=True`, captured URL lacks a trailing slash, the slash-appended
   path resolves, and the target view permits slash appending.
5. The fix must not change public signatures, URL pattern registration, or the
   `should_append_slash` protocol.

## Out of Scope for This Intent

- Changing behavior for URLs that already end in `/`.
- Redirecting when the slash-appended URL does not resolve.
- Redirecting when the resolved view opts out with `should_append_slash=False`.
- Proving the internals of URI escaping or URL resolving.
