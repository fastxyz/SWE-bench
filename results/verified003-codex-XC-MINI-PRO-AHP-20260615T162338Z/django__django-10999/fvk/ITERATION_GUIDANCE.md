# Iteration Guidance

Status: constructed, not machine-checked.

## Code decision

V1 stands unchanged. The audit did not surface a blocking proof obligation that
V1 fails. Findings F1-F4 and proof obligations PO-1 through PO-7 support the
current source behavior.

## Why no V2 source edit was applied

- No behavior defect remained in the sign-placement family described by the
  issue.
- The dead microsecond-sign branch in Finding F5 is harmless and unreachable
  under the current regexes. Removing it would be cleanup, not an issue fix.
- Documentation could further clarify sign semantics, but the benchmark task is
  a source-code repair and hidden tests evaluate behavior. No doc edit is needed
  to satisfy the proof obligations.

## Tests to add in a normal development setting

These are recommendations only; no test files were modified.

- `parse_duration('-00:01:01') == -timedelta(seconds=61)`.
- `parse_duration('-01:01') == -timedelta(seconds=61)`.
- `parse_duration('00:-01:-01') is None`.
- `parse_duration('-01:-01') is None`.
- A signed-day preservation case such as
  `parse_duration('-1 01:03:05') == timedelta(days=-1, hours=1, minutes=3, seconds=5)`.
- Existing PostgreSQL signed-time-with-days cases should remain covered.

## Future verification work

- Machine-check the emitted K artifacts with the commands in `PROOF.md`.
- If exact regex semantics become important, replace the parsed-shape model with
  a richer string/regex model or a real Python semantics. That is a proof
  capability expansion, not a known bug in V1.
- Consider removing the dead `seconds.startswith('-')` microsecond branch in a
  separate cleanup patch after confirming no downstream branch reintroduces
  signed seconds.
