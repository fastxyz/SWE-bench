# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Default Handled Status Set

Statement:

```
go(request) delegates to go(request, {OK})
go(request, responseHandler) delegates to go(request, responseHandler, {OK})
```

Public evidence: E1-E4.

Code evidence:

```
DEFAULT_HANDLED_RESPONSE_STATUSES = ImmutableSet.of(HttpResponseStatus.OK)
```

Why it matters: a default `503` response is not caller-handled and therefore enters PO-4 instead of PO-2.

Finding links: F-001, F-002.

## PO-2: Handled Statuses Return Directly

Statement:

For any response holder `R` with status `S`, if `S` is in `responseStatusesToHandle`, then `go` returns `R` without refreshing the cached leader.

Symbolic form:

```
Response(S) and S in handledStatuses
  => Return(Response(S))
```

Code evidence:

```
} else if (responseStatusesToHandle.contains(responseStatus)) {
  return fullResponseHolder;
}
```

Public evidence: E4.

Finding links: F-002.

## PO-3: Temporary Redirects Keep Existing Redirect Semantics

Statement:

For status `TEMPORARY_REDIRECT`, the redirect branch runs before handled-status classification. It requires a `Location` header, validates it as a URL, updates `currentKnownLeader` to the redirect base URL, replaces the request URL, and continues.

Symbolic form:

```
Response(TEMPORARY_REDIRECT, Location = L valid)
  => currentKnownLeader' = base(L)
     and request' = withUrl(request, L)
     and Continue
```

Public/code evidence: E7 and existing redirect branch.

Finding links: F-001.

## PO-4: Unhandled Non-Redirect Status Refreshes Leader and Retries

Statement:

For any response holder `R` with status `S`, if `S` is not `TEMPORARY_REDIRECT`, `S` is not in `responseStatusesToHandle`, and retry budget remains, then `go` refreshes the cached leader using `getCurrentKnownLeader(false)`, rebuilds the request with the same method, path, query, headers, and content, and continues.

Symbolic form:

```
attempt < MAX_RETRIES - 1
and Response(S)
and S != TEMPORARY_REDIRECT
and S notin handledStatuses
and refresh(discovery) = leader'
  => request' = rebuild(request, leader')
     and Continue(attempt + 1)
```

Code evidence:

```
request = withCurrentKnownLeader(request);
```

and inside `withCurrentKnownLeader`:

```
getCurrentKnownLeader(false)
withUrl(request, new URL(leader + path [+ "?" + query]))
```

Public evidence: E1, E2, E3, E5.

Finding links: F-001.

## PO-5: Status-Retry Exhaustion or Refresh Failure Returns Final Response

Statement:

For unhandled non-redirect status `S`, if the status branch reaches the last retry attempt, `go` returns the current response. If cache refresh fails with `IOException` while handling an unhandled status, `go` returns the current response.

Symbolic form:

```
attempt = MAX_RETRIES - 1
and Response(S)
and S notin handledStatuses
  => Return(Response(S))

Response(S)
and S notin handledStatuses
and refresh(discovery) = NoLeader
  => Return(Response(S))
```

Code evidence:

```
if (counter == MAX_RETRIES - 1) {
  return fullResponseHolder;
}

catch (IOException e) {
  log.warn(e, "Unable to refresh leader for request[%s].", request.getUrl());
  return fullResponseHolder;
}
```

Public evidence: E6.

Finding links: F-001.

## PO-6: Transport Exception Behavior Is Preserved

Statement:

If an attempt throws `IOException` or `ChannelException`, `go` refreshes the cached leader using `getCurrentKnownLeader(false)`, rebuilds the request, and continues. If every attempt follows this transport-exception path, the existing retry-exhausted `IOE` is thrown after the loop.

Symbolic form:

```
TransportFailure and refresh(discovery) = leader'
  => request' = rebuild(request, leader') and Continue

all attempts are TransportFailure
  => Throw(IOE retries exhausted)
```

Code evidence:

```
catch (IOException | ChannelException ex) {
  request = withCurrentKnownLeader(request);
  continue;
}

throw new IOE("Retries exhausted, couldn't fulfill request to [%s].", request.getUrl());
```

Public evidence: E1, E5.

Finding links: F-001.

## PO-7: Public API Compatibility

Statement:

The original public overloads remain:

```
go(Request)
go(Request, HttpResponseHandler)
```

New overloads are additive:

```
go(Request, HttpResponseStatus...)
go(Request, Set<HttpResponseStatus>)
go(Request, HttpResponseHandler, HttpResponseStatus...)
go(Request, HttpResponseHandler, Set<HttpResponseStatus>)
```

Existing call sites that invoke `go(request)` still call the original virtual method shape, preserving public mocks and overrides that implement only `go(Request)`.

Public evidence: E8.

Finding links: F-003.

## PO-8: Handler Reuse Is Within Public Source Assumptions

Statement:

Status retries reuse the `HttpResponseHandler` object passed to `go`. The proof assumes public handlers used with this client are reusable for multiple attempts in one logical `go` call.

Code evidence:

```
fullResponseHolder = httpClient.go(request, responseHandler).get();
```

This is inside the retry loop.

Public source evidence:

Production call sites use stateless full-response handlers in the audited source.

Finding links: F-004.

## PO-9: Termination Bound

Statement:

The retry loop executes at most `MAX_RETRIES` iterations. On each `continue`, the Java `for` loop increments `counter`. Therefore partial correctness proof over each branch is not hiding an unbounded retry.

Code evidence:

```
for (int counter = 0; counter < MAX_RETRIES; counter++) {
  ...
}
```

Public evidence: E6 and existing `MAX_RETRIES` behavior.

Finding links: F-005.
