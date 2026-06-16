# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Claims Proved

The constructed proof covers the claims in `fvk/requests-method-spec.k` over the
fragment in `fvk/mini-python-requests-method.k`:

- `PREPARE-METHOD-PY2-UNICODE`: Python 2 unicode ASCII method token prepares to
  uppercase native string.
- `PREPARE-METHOD-PY2-NATIVE`: Python 2 native ASCII method token remains
  native and uppercase.
- `SESSION-REQUEST-PY2-UNICODE`: the `requests.request()` / `Session.request()`
  path, including repeated `.upper()` calls, prepares a Python 2 unicode ASCII
  method token to uppercase native string.
- `PREPARE-METHOD-NONE`: `None` remains `None`.

## Proof Sketch

For `PreparedRequest.prepare_method(method)`:

1. If `method is None`, the guard in the function is false and `self.method`
   remains `None`.
2. If `method` is not `None`, the function first computes
   `self.method.upper()`.
3. For ASCII method tokens, uppercasing preserves ASCII method-token status and
   is idempotent.
4. V1 then applies `to_native_string()` to the uppercased result.
5. On Python 2, `to_native_string(Unicode(S))` encodes ASCII unicode `S` to
   native `str`; `to_native_string(Native(S))` leaves native `str` unchanged.
6. Therefore the prepared method reaching `HTTPAdapter.send()` is
   `Native(upper(S))`, not unicode.

For the session path:

1. `Session.request()` constructs `Request(method=method.upper(), ...)`.
2. `Session.prepare_request()` calls `p.prepare(method=request.method.upper(),
   ...)`.
3. `PreparedRequest.prepare()` calls `prepare_method(method)`.
4. The extra `.upper()` calls preserve `upper(S)` by idempotence.
5. The final `prepare_method()` step applies PO-001, so the transport value is
   native.

## Adequacy Check

The formal English says that Python 2 unicode ASCII methods must be equivalent
to native ASCII methods at the prepared transport boundary. That matches the
public issue, which contrasts working `'POST'` with failing `u'POST'` and says
the unicode method should be a string before headers/body are assembled.

No formal claim preserves the reported `UnicodeDecodeError`; that traceback is
classified as the pre-fix bug.

## Residual Risk

- The proof is constructed, not machine-checked.
- The mini semantics models only method normalization and the relevant session
  forwarding shape, not full Python, full Requests, sockets, urllib3, or
  httplib.
- Termination is not separately proved. The modeled function has no loop.
- Non-ASCII method text is outside the proven domain.

## Machine-Check Commands

These commands are emitted for later verification only and were not run:

```sh
kompile fvk/mini-python-requests-method.k --backend haskell
kast --backend haskell fvk/requests-method-spec.k
kprove fvk/requests-method-spec.k
```

Expected result after a valid machine check: `kprove` returns `#Top` for the
claims in `fvk/requests-method-spec.k`.

## Test Guidance

No visible public test is safely removable based on this proof. Existing tests
cover integration behavior and unicode handling outside the exact method-native
contract. A future test should be added for `Request(method=u'POST', ...).prepare()`
on Python 2, asserting the prepared method is native `str` and equals `POST`.

