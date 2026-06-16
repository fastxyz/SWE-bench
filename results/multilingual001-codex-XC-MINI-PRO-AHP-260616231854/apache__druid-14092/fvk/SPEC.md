# FVK Spec: DruidLeaderClient Status Retry

Status: constructed, not machine-checked.

## Scope

Target production unit: `repo/server/src/main/java/org/apache/druid/discovery/DruidLeaderClient.java`.

Verified behavior is the retry-control part of `DruidLeaderClient.go(Request, HttpResponseHandler, Set<HttpResponseStatus>)` and the default `go` overloads that delegate to it. The model abstracts away the HTTP body type and response handler internals, retaining only the observable status, redirect case, transport-failure case, cached-leader refresh, retry bound, and returned/thrown result.

## Intent-Only Obligations

I1. On `IOException` or `ChannelException`, the leader cache is refreshed before retry.

I2. Proxy or sidecar HTTP failures such as `503 Service Unavailable` are not valid caller-handled responses by default; they must trigger cache refresh and retry.

I3. Callers must be able to declare HTTP statuses that they want to handle directly.

I4. If a status-based retry still cannot get a handled response, the final HTTP response is returned to the caller.

I5. Existing redirect handling remains special: temporary redirects update the known leader from the `Location` header and retry that location.

I6. The retry budget remains the existing `MAX_RETRIES = 5`; termination of the retry loop follows from that finite bound.

I7. Existing public method signatures remain source-compatible: old `go(request)` and `go(request, responseHandler)` calls still compile and dispatch.

## Public Evidence Ledger

| Id | Source | Quoted Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "DruidLeaderClient should refresh cache for non-200 responses" | Non-OK responses not claimed by the caller must refresh cached leader. | Encoded by PO-2, PO-4. |
| E2 | `benchmark/PROBLEM.md` | "getting errors from the proxy itself such as a 503" | `503`-class proxy responses are in-domain examples of unhandled response statuses. | Encoded by default handled set `{OK}` and PO-4. |
| E3 | `benchmark/PROBLEM.md` | "treats 503 as a valid response and propogates it back to the caller" | V1 must not return first unhandled status immediately when retries remain. | Encoded by PO-4. |
| E4 | `benchmark/PROBLEM.md` | "allow callers to pass in the HTTP responses which they want to handle" | Add an API path for caller-declared handled statuses. | Encoded by overloads and PO-1, PO-2. |
| E5 | `benchmark/PROBLEM.md` | "for anything else we do a best-effort retry inside the DruidLeaderClient ... by clearing the cache" | Non-handled statuses must use the same leader refresh path as transport failures. | Encoded by PO-4 and helper `withCurrentKnownLeader`. |
| E6 | `benchmark/PROBLEM.md` | "which if its still unsuccessful is returned to the caller to deal with(existing behavior)" | If response-status retries are exhausted or refresh cannot find a replacement, return the HTTP response. | Encoded by PO-5. |
| E7 | Existing code comment and control flow | `TEMPORARY_REDIRECT` branch updates `currentKnownLeader` from `Location`. | Redirect branch remains before handled-status classification. | Encoded by PO-3. |
| E8 | Existing public tests and subclasses | Public test mocks and a test subclass override `go(Request)`. | Avoid changing existing call-site method shape unless needed by intent. | Encoded by PO-7; supports keeping V1 call sites unchanged. |

## Formal State Model

The model for one `go` execution uses the tuple:

```
State = <attempt, request, currentKnownLeader, discovery, handledStatuses, nextOutcome>
```

where:

- `attempt` ranges over `0..MAX_RETRIES - 1`.
- `request` carries `method`, `path`, `query`, `headers`, and optional `content`.
- `currentKnownLeader` is the cached leader base URL.
- `discovery` is the public node-discovery source consulted by `getCurrentKnownLeader(false)`.
- `handledStatuses` is the set supplied by the caller, defaulting to `{OK}`.
- `nextOutcome` is one of `TransportFailure`, `Redirect(location)`, `Response(status)`, or `RefreshFailure`.

The status retry property is independent of the response body value `T`; therefore the proof treats `FullResponseHolder<T>` as a holder containing a status and opaque content.

## Intended Transition Relation

R1. `TransportFailure`:

```
attempt < MAX_RETRIES
  => refresh leader with cached=false; rebuild request with same method/path/query/headers/content; continue
```

If all attempts are consumed by transport failures, the method throws the existing retry-exhausted `IOE`.

R2. `Redirect(location)`:

```
Location exists and is a valid URL
  => currentKnownLeader := base(location); request := withUrl(request, location); continue
```

Missing or malformed `Location` throws the existing `IOE`.

R3. `Response(status)` and `status in handledStatuses`:

```
return response
```

R4. `Response(status)` and `status not in handledStatuses` and `attempt < MAX_RETRIES - 1`:

```
refresh leader with cached=false; rebuild request with same method/path/query/headers/content; continue
```

R5. `Response(status)` and `status not in handledStatuses` and `attempt == MAX_RETRIES - 1`:

```
return response
```

R6. `Response(status)` and `status not in handledStatuses` but refresh fails:

```
return response
```

This is the "best effort" behavior from E6.

## English Adequacy Check

The formal model says exactly: by default, only `200 OK` is handled directly; a non-redirect status such as `503` refreshes the leader and retries while budget remains; explicit caller-handled statuses are returned directly; persistent unhandled statuses are eventually returned; transport exceptions keep the old exception retry behavior; redirects keep the existing redirect behavior.

This matches I1 through I7. The only intentionally unproven area is caller-by-caller policy selection for statuses such as `404`. That policy is supported by the new overloads, but V2 does not migrate public callers because E8 makes broad call-site churn a compatibility risk and the reported stale-cache defect is fixed by the default path.

## K Artifact Note

Supplemental K artifacts are present:

- `fvk/mini-druid-leader-client.k`
- `fvk/druid-leader-client-spec.k`

They encode the retry-control transition model above. The commands that would machine-check them are recorded in `fvk/PROOF.md`; they were not run.
