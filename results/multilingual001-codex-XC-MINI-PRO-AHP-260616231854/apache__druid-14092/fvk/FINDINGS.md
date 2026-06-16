# FVK Findings

Status: constructed, not machine-checked.

## F-001: Reported 503 Stale-Cache Path Is Addressed

Classification: confirmed fixed by V1.

Evidence:

- Problem evidence E1-E6 in `fvk/SPEC.md`.
- Proof obligations PO-1 through PO-5 in `fvk/PROOF_OBLIGATIONS.md`.

Input/state:

```
currentKnownLeader = stale leader A
request = path P, optional query Q, headers H, optional content C
handledStatuses = default {OK}
attempt = 0
httpClient.go(request to A) returns status 503
discovery can provide leader B
```

Observed in pre-fix behavior:

```
503 response returned immediately; currentKnownLeader remains A; caller retry reuses A.
```

Expected from public intent:

```
503 is not handled by default, so DruidLeaderClient refreshes the cached leader, rebuilds the request for B with P/Q/H/C preserved, and retries before returning a final persistent failure.
```

V1 behavior:

```
responseStatus = 503
503 not in DEFAULT_HANDLED_RESPONSE_STATUSES
counter < MAX_RETRIES - 1
request = withCurrentKnownLeader(request)
continue
```

Finding result: no V2 source change required.

## F-002: Caller-Declared Handled Status API Exists

Classification: confirmed fixed by V1.

Evidence:

- Problem evidence E4.
- Proof obligations PO-1 and PO-2.

Input/state:

```
handledStatuses = {OK, NOT_FOUND}
httpClient.go(request) returns 404
```

Expected from public intent:

```
404 is passed onward when a caller declares it handles 404.
```

V1 behavior:

```
go(request, HttpResponseStatus.OK, HttpResponseStatus.NOT_FOUND)
  delegates to go(request, ImmutableSet.of(OK, NOT_FOUND))
responseStatusesToHandle.contains(404) is true
return fullResponseHolder
```

Finding result: no V2 source change required.

## F-003: Existing Public Call Sites Are Not Migrated to the New Overloads

Classification: intentional compatibility decision, not a code bug for this issue.

Evidence:

- Problem evidence E4 permits callers to pass handled statuses, but does not require every existing caller to be migrated in this patch.
- Public compatibility evidence E8: in-repo mocks and a subclass override `go(Request)`, so changing call sites to a new overload would create broad method-shape churn unrelated to the reported stale-cache symptom.
- Proof obligation PO-7 preserves old call signatures and dispatch shape.

Input/state:

```
existing production caller invokes go(request)
response status = 404
```

Observed in V1:

```
404 is unhandled by the default {OK} policy, so DruidLeaderClient may refresh and retry before eventually returning 404.
```

Expected from public intent:

```
For the reported proxy failure class, default non-OK refresh is required. For caller-specific non-OK policies, the API must allow opt-in handled statuses.
```

Finding result: no V2 source change required. Future targeted migrations of call sites that intentionally handle `404` are reasonable only with corresponding public-callsite and override audit coverage.

## F-004: Response Handler Reuse Across Status Retries Is Acceptable for Public Callers Audited

Classification: assumption confirmed by public source scan.

Evidence:

- Public production call sites using custom handlers instantiate stateless `StringFullResponseHandler`, `BytesFullResponseHandler`, or `InputStreamFullResponseHandler`.
- Proof obligation PO-8 states this assumption explicitly.

Input/state:

```
custom response handler H
first attempt returns unhandled status
second attempt reuses H
```

Observed risk:

```
A stateful handler could in principle retain data from the first response.
```

Expected from public source evidence:

```
The public handlers used with DruidLeaderClient do not retain per-response mutable state across calls in a way that affects the next holder.
```

Finding result: no V2 source change required. If future callers provide stateful handlers, they should either pass handled statuses to avoid retries or use a fresh handler per `go` call.

## F-005: Proof Is Constructed, Not Machine-Checked

Classification: verification process limitation, not a code bug.

Evidence:

- User instructions forbid running tests, Python, K tooling, `kompile`, or `kprove`.
- `fvk/PROOF.md` records the commands that would be run in an execution-capable environment.

Finding result: do not claim machine-checked proof; keep tests and hidden evaluator expectations intact.
