# Proof Obligations

Status: constructed, not machine-checked.

## O-001: Reject Authority-Form Protocol-Relative Targets

For every `fullPath`, if `fullPath` after leading C0/space trimming begins with two separators from the set `{ '/', '\\' }`, the HTTP adapter must reject with `AxiosError.ERR_INVALID_URL` before calling `new URL(fullPath, 'http://localhost')`.

Linked findings: F-001.

## O-002: Preserve Non-Protocol-Relative Parsing

For every `fullPath` that does not satisfy O-001's predicate, the new guard must not reject; control must continue to the existing URL parse and protocol checks.

Linked findings: F-003.

## O-003: BaseURL Bypass Case Is Covered

If `buildFullPath(baseURL, requestedURL)` returns a protocol-relative `requestedURL` untouched because it is considered absolute, O-001 must still reject the resulting `fullPath`.

Linked findings: F-001.

## O-004: Ordinary Relative Paths Are Not Over-Rejected

Ordinary relative paths, including paths combined with `baseURL` into `https://...`, must not match the new authority-form guard.

Linked findings: F-003.

## O-005: Source And CommonJS Bundle Parity

The same predicate and rejection behavior must exist in `repo/lib/adapters/http.js` and `repo/dist/node/axios.cjs`.

Linked findings: F-002.

## O-006: Error Shape

The rejection should use the existing axios error type and code, `AxiosError` with `AxiosError.ERR_INVALID_URL`, so callers get an axios-classified invalid URL failure.

Linked findings: F-001.
