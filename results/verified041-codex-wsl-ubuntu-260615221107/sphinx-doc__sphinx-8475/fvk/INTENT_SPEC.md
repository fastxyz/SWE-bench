# Intent Spec

Status: intent-only, written before accepting candidate behavior as correct.

## Required Behavior

1. For an HTTP/HTTPS link without an anchor check, linkcheck should try `HEAD`
   first.
2. If `HEAD` succeeds, linkcheck should classify the link from the `HEAD`
   response and should not fall back to `GET`.
3. If `HEAD` fails with an HTTP status error, linkcheck should preserve the
   existing `GET` fallback behavior.
4. If `HEAD` fails with `requests.exceptions.TooManyRedirects`, linkcheck should
   retry with `GET` instead of immediately reporting the link as broken.
5. The result after a `HEAD` `TooManyRedirects` fallback should be whatever the
   `GET` path establishes: working, redirected, unauthorized-working,
   ignored-503, or broken if `GET` also fails.
6. Anchor checks remain out of this issue's change path because they already use
   `GET` to inspect response content.
7. Public signatures, config names, output record shape, and result caching
   should remain compatible.

## Default-Domain Assumptions

- Requests raises `TooManyRedirects` as an exception from the request operation
  when redirect limits are exceeded.
- This FVK pass proves partial correctness for the request-decision branch; it
  does not prove network termination or Requests internals.
