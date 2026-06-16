# Public Compatibility Audit

Changed public symbol:

- `requests.models.PreparedRequest.prepare_method(self, method)`

## Signature

No change.

## Return Shape

No change. The method mutates `self.method` and returns `None` as before.

## Observable Behavior Change

For Python 2 unicode ASCII method tokens, `self.method` is now native `str`
after preparation. This is required by the issue and aligns method handling with
existing native header-name handling.

## Public Callsites Checked

- `Request.prepare()` calls `PreparedRequest.prepare(...)`, which calls
  `prepare_method()`.
- `Session.prepare_request()` calls `PreparedRequest.prepare(...)`, which calls
  `prepare_method()`.
- `Session.request()` constructs a `Request` and then calls
  `Session.prepare_request()`.
- `HTTPAdapter.send()` consumes `request.method` from the prepared request.

## Overrides/Subclasses

No in-repository subclass override of `PreparedRequest.prepare_method()` was
found by source inspection.

## Compatibility Verdict

Pass. V1 changes only the intended Python 2 runtime type for unicode ASCII
methods at the prepared request boundary.

