# Baseline Notes

## Root Cause

`DruidLeaderClient` refreshed its cached leader only when the HTTP request failed with an `IOException` or `ChannelException`, or when the response was a temporary redirect. A non-redirect HTTP response such as `503 Service Unavailable` was treated as a completed response and returned immediately to the caller. If that response came from a proxy or sidecar in front of a stale leader address, retries in caller code reused the same cached leader and never forced leader rediscovery.

## Changed Files

- `repo/server/src/main/java/org/apache/druid/discovery/DruidLeaderClient.java`
  - Added status-aware `go` overloads so callers can declare which HTTP statuses they intend to handle directly.
  - Made the default handled status set `200 OK`; other non-redirect statuses now refresh the cached leader using the same rediscovery path used for transport failures and retry up to the existing retry limit.
  - Return the final unhandled HTTP response to the caller if status-based retries are exhausted or if leader refresh cannot find a replacement, preserving caller-level handling for persistent HTTP failures.
  - Extracted the request URL rebuild logic into `withCurrentKnownLeader` so exception retries and response-status retries use the same cache-refresh behavior.
- `reports/baseline_notes.md`
  - Added this required explanation of the root cause, implementation choices, assumptions, and rejected alternatives.

## Assumptions

- The proxy/sidecar failure described in the issue should be handled by retrying statuses that callers did not explicitly opt into handling.
- The existing `MAX_RETRIES` value remains the correct retry budget for status-based retries.
- `200 OK` is the safe default handled status for existing callers; persistent non-OK responses are still returned after the retry budget is exhausted.
- Temporary redirects should continue to use the existing redirect handling before any handled-status decision.

## Alternatives Considered

- Updating every existing caller to pass explicit handled statuses was rejected because it would create broad, mock-visible churn outside the reported bug. The new overloads make that possible for callers that need it without forcing unrelated call-site edits.
- Retrying only `503 Service Unavailable` was rejected because the issue describes the broader class of proxy-generated non-success responses, and the new API lets callers opt out specific statuses they own.
- Throwing an exception when status-based retries are exhausted was rejected because callers already receive and interpret HTTP responses; returning the final response preserves that contract.

## Verification

No tests or project code were run, per the benchmark instructions. I limited verification to source inspection and `git diff --check`.
