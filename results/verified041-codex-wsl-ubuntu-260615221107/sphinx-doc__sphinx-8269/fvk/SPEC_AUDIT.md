# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent entries | Verdict | Notes |
| --- | --- | --- | --- |
| LC-HTTP-ERROR-FIRST | I-1, I-2; E-1, E-2, E-3, E-4 | Pass | Directly encodes that HTTP errors are reported before anchor-not-found. |
| LC-401-PRESERVED | I-2; E-3, E-7 | Pass | Preserves existing HTTPError policy for 401. |
| LC-503-PRESERVED | I-2; E-3, E-7 | Pass | Preserves existing HTTPError policy for 503. |
| LC-OK-MISSING-ANCHOR | I-3; E-5, E-8 | Pass | Keeps anchor validation for successful responses. |
| LC-OK-FOUND-SAME-URL | I-4; E-5 | Pass | Leaves successful found-anchor classification unchanged. |
| LC-OK-FOUND-REDIRECT | I-4; E-5 | Pass | Leaves successful redirect classification unchanged. |

## Adequacy Result

The formal claims are neither weaker nor stronger than the public intent for the audited branch. The model deliberately abstracts the parser implementation, network transport, and retry loop, but it preserves the observable axis under audit: whether a response is reported as HTTP error, missing anchor, working, ignored, or redirected, and whether anchor parsing happens before or after HTTP status classification.

No claim depends on the legacy buggy behavior. Existing public tests for missing anchors are interpreted only as successful-response evidence and do not conflict with the issue's HTTP-error requirement.
