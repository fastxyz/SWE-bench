# Spec Audit

| Formal-English obligation | Intent match | Notes |
|---|---|---|
| Spec-compliant Node `FormData` becomes stream data with boundary-bearing multipart headers. | Pass | Matches INTENT_SPEC items 1-3 and ledger E1-E4. |
| Legacy `form-data` package remains on its original branch. | Pass | Matches INTENT_SPEC item 4 and ledger E5. |
| Unrelated unsupported objects still reject with the existing error. | Pass | Frame condition inferred from the issue being specific to Node 18 `FormData`; no public evidence asks to broaden arbitrary object support. |
| CJS public path must behave like source path. | Pass after V2 | This was ambiguous/failing in V1 because only `lib/` changed. V2 mirrors the fix in `dist/node/axios.cjs`, satisfying ledger E3/E6 in this no-build workspace. |

No formal-English obligation relies only on V1 behavior. The one V1-derived gap, stale CommonJS output, was promoted to Finding F2 and fixed.
