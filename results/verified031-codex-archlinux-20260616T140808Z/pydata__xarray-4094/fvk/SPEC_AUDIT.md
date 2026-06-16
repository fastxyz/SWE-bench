# Spec Audit

Status: adequacy comparison; constructed, not machine-checked.

| Formal claim | Intent entries | Result | Notes |
| --- | --- | --- | --- |
| C1 non-stacked guard | Intent 1, E7 | Pass | Keeps the existing public error behavior. |
| C2 single-level stacked roundtrip | Intent 2-5, E1-E5 | Pass | Directly covers the reported issue and the sample-dimension frame condition. |
| C3 mixed one-real-level roundtrip | Intent 3, 6, E4, E6 | Pass | Preserves existing mixed-dimensional behavior while making missing-level squeezing explicit. |
| C4 merge compatibility | Intent 2, E2 | Pass | Prevents the reported `MergeError` mechanism. |
| C5 public compatibility | Intent 1-3, E7 | Pass | No signature or return-type change. |

## Adequacy notes

The V1 proof attempt would have failed this audit because "all length-one
dimensions may be squeezed" was implementation-derived from `.squeeze(drop=True)`
and contradicted the `sample_dims` frame condition in E5. V2 replaces that with
targeted squeezing.
