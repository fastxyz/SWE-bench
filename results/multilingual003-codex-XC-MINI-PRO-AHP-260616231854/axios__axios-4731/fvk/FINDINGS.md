# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public intent and source inspection only.

## F-001: Pre-fix follow-redirects inherited a finite default for axios unlimited bodies

- Classification: code bug, resolved.
- Evidence: E1, E2, E3, E6 in `fvk/SPEC.md`.
- Input: `maxBodyLength = -1`, `config.transport` absent, `config.maxRedirects !== 0`.
- Observed in V0: axios omitted `options.maxBodyLength`, so `follow-redirects` could apply its own finite default.
- Expected: axios' unlimited sentinel must be represented downstream as `Infinity` on the `follow-redirects` path.
- Resolution: V2 sets `options.maxBodyLength = Infinity` when `config.maxBodyLength <= -1`, no custom transport is supplied, and redirects are not disabled.
- Proof obligations: PO-001, PO-002.

## F-002: V1 fixed the bug but changed unrelated option shape for native/custom transports

- Classification: compatibility overreach, resolved.
- Evidence: E4, E9, E10 in `fvk/SPEC.md`.
- Input: `maxBodyLength = -1`, and either `maxRedirects === 0` or `config.transport` is supplied.
- Observed in V1: `options.maxBodyLength` was always assigned `Infinity` for unlimited values, including branches that do not use `follow-redirects`.
- Expected: only the branch that needs to override `follow-redirects`' finite default should receive the new `Infinity` option; native and custom transport unlimited option shape should stay as before.
- Resolution: V2 narrows the `Infinity` assignment to `!config.transport && config.maxRedirects !== 0`.
- Proof obligations: PO-003, PO-004.

## F-003: Explicit finite and `Infinity` values must remain pass-through values

- Classification: frame condition, confirmed.
- Evidence: E5, E8 in `fvk/SPEC.md`.
- Input: `maxBodyLength > -1`, including `Infinity`.
- Expected: axios passes the explicit configured value downstream and the existing buffered-data preflight still rejects only when a finite configured limit is exceeded.
- Resolution: V2 preserves the original `if (config.maxBodyLength > -1)` assignment for all transport branches.
- Proof obligations: PO-005.

## F-004: Documentation gap remains outside this source-code repair

- Classification: residual documentation gap.
- Evidence: issue text says the default limit should be "documented".
- Input: developer reads the README config block for `maxBodyLength`.
- Observed: README shows `maxBodyLength: 2000` but does not document that `-1` is the default unlimited sentinel.
- Expected: docs should state the default/unlimited behavior.
- Resolution in this run: no source-code change. The benchmark instructions target non-test source code; this finding should feed a documentation-only follow-up.
- Proof obligations: PO-006.

## F-005: Nonstandard numeric values are underspecified

- Classification: underspecified intent, no code change.
- Evidence: public type is `number`, but issue examples cover `-1`, finite large strings, `0` redirects, and `Infinity`.
- Input: `maxBodyLength = NaN`, `null`, or another nonstandard non-number after config construction.
- Observed/expected: not specified by public issue or docs reviewed here.
- Resolution: excluded from the FVK domain. Do not use this proof to make claims about those values.
- Proof obligations: PO-007.
