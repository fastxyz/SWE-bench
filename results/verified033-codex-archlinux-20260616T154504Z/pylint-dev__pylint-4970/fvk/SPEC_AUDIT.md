# Spec Audit

| Formal claim | Intent coverage | Verdict |
| --- | --- | --- |
| DISABLED-COMPUTE | Matches E1, E3, and E4: a zero threshold disables similarity results, preventing duplicate-code messages at the shared computation boundary. | Pass |
| DISABLED-PROCESS | Matches E1, E4, and E7: "stop checking" is interpreted as avoiding local duplicate-code collection work, not only suppressing final messages. | Pass |
| DISABLED-CLOSE | Matches E3: no duplicate-code messages and zero duplicated-line stats follow from the empty similarity list. | Pass |
| POSITIVE-PRESERVATION | Matches E4 by limiting the behavior change to disabled values and preserving the existing positive threshold semantics. | Pass |
| PARALLEL-REDUCE | Matches E1-E4 across Pylint's parallel checker path; without it, a disabled serial proof would not cover all public execution modes. | Pass |

## Ambiguities

- Public intent names exactly `0`; it does not specify negative values. The code
  treats `min_lines <= 0` as disabled. This is accepted as a default-domain
  assumption because negative minimum line counts are not meaningful, but it is
  not a separate public requirement.

## Compatibility

No claim depends on hidden tests, original upstream fixes, or evaluator output.
The spec does not preserve the pre-fix behavior that emitted many duplicate-code
messages with `0`, because the issue explicitly identifies that behavior as the
bug.
