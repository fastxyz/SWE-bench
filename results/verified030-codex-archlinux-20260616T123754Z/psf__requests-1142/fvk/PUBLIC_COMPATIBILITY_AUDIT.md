# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed public symbols

`Request.__init__`

- Signature: unchanged.
- Return type: unchanged.
- Stored attributes: unchanged names.
- Internal normalization changed from `data=None -> []` to `data=None -> {}`.
- Compatibility result: acceptable. The docstring describes `data` as the body
  to attach. `None` denotes no body, and omitted data already used an empty dict
  default. V2 makes the explicit `None` spelling match the omitted-data spelling.

`PreparedRequest.prepare_content_length`

- Signature: unchanged.
- Return type: unchanged (`None`, mutates headers).
- Compatibility result: acceptable. The method now skips only the automatic
  zero-length insertion for bodyless `GET`.

## Public callsites reviewed

- `Session.request` assigns `req.data = data` directly. With `data=None`, it
  already reaches the bodyless path in `prepare_body`; V2 does not break this.
- `Request.prepare` calls `prepare_body(self.data, self.files)` unchanged.
- `PreparedRequest.prepare_auth` recomputes content length unchanged, but now
  observes the same bodyless-GET guard.

## Subclasses and overrides

No in-repository subclasses or overrides of the changed methods were found in
the allowed source. No virtual dispatch signature changed.
