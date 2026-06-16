# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, tests, Python, or project code were run.

## Claim

For every started `DruidLeaderClient`, request, response handler, and caller-supplied handled-status set:

1. A handled non-redirect HTTP status is returned directly.
2. An unhandled non-redirect HTTP status refreshes the cached leader and retries while retry budget remains.
3. If status retries are exhausted, or the refresh attempt fails while processing an unhandled status, the current HTTP response is returned.
4. Transport exceptions retain the prior refresh-and-retry behavior, with retry exhaustion throwing the existing `IOE`.
5. Temporary redirects retain the prior redirect behavior and are processed before status membership checks.

The default overloads instantiate the handled-status set as `{HttpResponseStatus.OK}`.

## Mini-Semantics

The proof uses the transition model in `fvk/SPEC.md`:

```
Outcome ::= TransportFailure
          | Redirect(validLocation)
          | Redirect(invalidOrMissingLocation)
          | Response(status)

Handled(status, handledStatuses) ::= status in handledStatuses
RedirectStatus(status) ::= status == TEMPORARY_REDIRECT
Refresh(discovery) ::= leader' | NoLeader
```

The abstract `rebuild(request, leader')` function preserves:

```
method(request)
path(request)
query(request)
headers(request)
content(request)
```

and changes only the URL base to `leader'`.

## Constructed Branch Proof

### Branch A: Transport Failure

Premise:

```
Outcome = TransportFailure
```

Java path:

```
catch (IOException | ChannelException ex) {
  request = withCurrentKnownLeader(request);
  continue;
}
```

By PO-6, `withCurrentKnownLeader` calls `getCurrentKnownLeader(false)` and then `withUrl`, so the next state is a retry state whose request points at the refreshed leader and preserves path/query/headers/content. The loop counter advances by the Java `for` update. If every iteration follows this path, the loop exits and throws the existing retry-exhausted `IOE`.

Result: PO-6 holds.

### Branch B: Temporary Redirect

Premise:

```
Outcome = Response(TEMPORARY_REDIRECT)
```

Java path:

```
if (HttpResponseStatus.TEMPORARY_REDIRECT.equals(responseStatus)) {
  ...
  currentKnownLeader.set(base(redirectUrl));
  request = withUrl(request, redirectUrl);
}
```

This branch is tested before `responseStatusesToHandle.contains(responseStatus)`. Therefore, even if a caller supplied `TEMPORARY_REDIRECT` in the handled set, the redirect branch remains the operative branch. A missing or malformed `Location` throws the existing `IOE`; a valid `Location` updates the cached leader and retries the redirect URL.

Result: PO-3 holds.

### Branch C: Handled Non-Redirect Status

Premise:

```
Outcome = Response(S)
S != TEMPORARY_REDIRECT
S in handledStatuses
```

Java path:

```
} else if (responseStatusesToHandle.contains(responseStatus)) {
  return fullResponseHolder;
}
```

Since the redirect condition is false and membership is true, the method returns the response from the current attempt without calling `withCurrentKnownLeader`.

Result: PO-2 holds.

### Branch D: Unhandled Non-Redirect Status With Retry Budget Remaining

Premise:

```
Outcome = Response(S)
S != TEMPORARY_REDIRECT
S notin handledStatuses
counter < MAX_RETRIES - 1
Refresh(discovery) = leader'
```

Java path:

```
if (counter == MAX_RETRIES - 1) {
  return fullResponseHolder;
}

request = withCurrentKnownLeader(request);
```

The last-attempt condition is false. By PO-4, `withCurrentKnownLeader` refreshes with `cached=false` and rebuilds the request over `leader'`. The loop continues to the next counter value.

For the reported example `S = SERVICE_UNAVAILABLE`, `S notin {OK}`, so this is the branch taken by the default overload.

Result: PO-4 and finding F-001 hold.

### Branch E: Unhandled Non-Redirect Status on Last Attempt

Premise:

```
Outcome = Response(S)
S != TEMPORARY_REDIRECT
S notin handledStatuses
counter == MAX_RETRIES - 1
```

Java path:

```
if (counter == MAX_RETRIES - 1) {
  return fullResponseHolder;
}
```

The current response is returned. This is exactly the best-effort fallback described by the issue: persistent HTTP failure is handed to the caller after internal retry opportunities are spent.

Result: first half of PO-5 holds.

### Branch F: Unhandled Non-Redirect Status With Refresh Failure

Premise:

```
Outcome = Response(S)
S != TEMPORARY_REDIRECT
S notin handledStatuses
counter < MAX_RETRIES - 1
Refresh(discovery) = NoLeader
```

Java path:

```
catch (IOException e) {
  log.warn(e, "Unable to refresh leader for request[%s].", request.getUrl());
  return fullResponseHolder;
}
```

Since the status response was already obtained, the refresh is best effort. If no replacement leader can be resolved, the current response is returned to the caller.

Result: second half of PO-5 holds.

## Default Overload Proof

`go(Request)` calls:

```
return go(request, DEFAULT_HANDLED_RESPONSE_STATUSES);
```

`go(Request, HttpResponseHandler)` calls:

```
return go(request, responseHandler, DEFAULT_HANDLED_RESPONSE_STATUSES);
```

`DEFAULT_HANDLED_RESPONSE_STATUSES = {OK}`. Therefore a default `503` cannot satisfy Branch C and must take Branch D, E, or F. With retry budget and a replacement leader, Branch D is forced.

Result: PO-1 and finding F-001 hold.

## Compatibility Proof

The original method signatures remain present. Existing source call sites that call `go(request)` still target `go(Request)`; subclasses overriding only that method remain applicable to those calls. The new status-aware overloads are additive.

Result: PO-7 and finding F-003 hold.

## Proof-Derived Findings

- F-001: the reported default `503` stale-cache path is fixed.
- F-002: caller-declared handled statuses are supported.
- F-003: not migrating all public call sites is an intentional compatibility choice, not a proof gap for the reported defect.
- F-004: status retry reuses the handler; audited public handlers are reusable/stateless for the modeled purpose.
- F-005: this is constructed, not machine-checked.

## Machine-Check Commands Not Run

The benchmark forbids running K tooling. In an execution-capable environment, the corresponding commands for a full FVK machine check would be recorded as:

```sh
kompile fvk/mini-druid-leader-client.k --backend haskell
kast --backend haskell fvk/druid-leader-client-spec.k
kprove fvk/druid-leader-client-spec.k
```

Expected successful outcome: `#Top`.

## Test Recommendation

No test files were edited. Because this proof is not machine-checked and the user forbids running tests, no test should be removed. Tests to keep include integration tests around leader discovery, redirect handling, and existing callers that interpret non-OK statuses. Useful future tests would cover:

- default `go(request)` receives `503` on the first leader, refreshes discovery, and retries another leader;
- `go(request, OK, NOT_FOUND)` returns a `404` directly;
- persistent `503` after the retry budget returns the final response;
- transport exceptions still throw retry-exhausted `IOE` after the existing retry budget.
