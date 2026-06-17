# FVK Findings

Status: constructed, not machine-checked.

## F1 - Pre-fix code skipped non-lowercase gzip values

- Evidence: `benchmark/PROBLEM.md` reports `GZIP`, `Gzip`, and `GZip` response values.
- Input: `decompress !== false`, method not `HEAD`, status not `204`, `content-encoding: GZIP`.
- Observed in pre-fix code: switch compared the raw value to lowercase `gzip`, so no decoder was added and the encoded body was returned.
- Expected: the gzip decoder should be added and `content-encoding` should be deleted after decoding.
- Classification: code bug.
- Resolution: V1/V2 compare the switch value after normalization.
- Related proof obligations: O1, O2, O5.

## F2 - V1 normalized case but not optional surrounding whitespace

- Evidence: intent ledger I6, the default HTTP token assumption.
- Input: `decompress !== false`, method not `HEAD`, status not `204`, `content-encoding: " GZIP "`.
- Observed in V1: `String(E || '').toLowerCase()` produced `" gzip "`, which would not match `gzip`.
- Expected: token comparison should ignore surrounding optional whitespace and ASCII case.
- Classification: code refinement found by formalization.
- Resolution: V2 uses `String(E || '').trim().toLowerCase()` in both adapter copies.
- Related proof obligations: O1, O6.

## F3 - Existing guard behavior must be preserved

- Evidence: adapter comments and branch ordering in `repo/lib/adapters/http.js`.
- Inputs: `decompress === false`; absent header; `HEAD`; `204`; unsupported encoding.
- Expected: these paths should not gain a decoder from the case-insensitive change.
- Classification: frame condition.
- Resolution: V2 changes only the switch expression and leaves the outer guard, no-content branch, and supported-case bodies intact.
- Related proof obligations: O3, O4, O7.

## F4 - Stacked encodings remain outside this fix

- Evidence: issue describes a singular value such as `GZIP`; the existing adapter switch also supports only one content-coding token at this point.
- Input: `content-encoding: "gzip, br"`.
- Observed/expected: V2 keeps existing behavior and does not attempt to decode stacked encodings.
- Classification: underspecified intent / out-of-scope behavior.
- Recommended future question: Should axios support comma-separated stacked `Content-Encoding` values in the Node adapter, and in which order should decoders be applied?
- Related proof obligations: O8.

## F5 - No test or tool execution was performed

- Evidence: task instructions forbid tests, Python, and K tooling execution.
- Impact: proof artifacts and commands are constructed but not machine-checked.
- Classification: proof process limitation, not a code bug.
- Related proof obligations: O9.
