# Findings

Status: constructed, not machine-checked.

## F1: V0 component-local signs violate leading-minus intent

- Classification: code bug fixed by V1.
- Evidence: E3, E4, E5; PO-1 and PO-2.
- Concrete input: `-00:01:01`.
- V0 observed behavior from the issue: positive 61 seconds.
- Expected behavior: negative 61 seconds.
- Cause: the old standard regex captured `-00` as a signed hours component and
  left minutes and seconds positive.
- V1 status: fixed. A separate leading `sign` now multiplies the whole no-day
  time value.

## F2: Existing public negative no-day tests are suspect legacy evidence

- Classification: stale/suspect public-test obligation.
- Evidence: E8 conflicts with E3-E5; PO-1.
- Concrete inputs: `-15:30` and `-1:15:30`.
- Legacy expected behavior in public tests: component-local signs, e.g.
  `minutes=-15, seconds=30`.
- Intent-derived expected behavior: leading `-` negates the whole standard
  no-day time value.
- V1 status: intentionally follows public issue intent rather than the stale
  component-sign expectations.

## F3: V1 satisfies the sign-placement proof obligations

- Classification: confirmation.
- Evidence: PO-1 through PO-5.
- Concrete inputs:
  - `-00:01:01` maps to negative 61 seconds.
  - `-01:01` maps to negative 61 seconds.
  - `00:-01:-01` is invalid.
  - `-01:-01` is invalid.
- V1 status: no additional code change required.

## F4: Other documented duration families are framed

- Classification: compatibility confirmation.
- Evidence: PO-6 and PO-7.
- Concrete examples from public tests/docs: `1 day -0:00:01`,
  `-1 day +0:00:01`, and ISO 8601 values such as `PT5S`.
- V1 status: no code change required because those regexes and arithmetic paths
  were not edited.

## F5: Dead legacy microsecond-sign branch remains

- Classification: non-blocking cleanup observation.
- Evidence: PO-2 removes negative standard seconds; ISO 8601 and PostgreSQL
  seconds are also unsigned.
- Concrete branch:
  `if kw.get('seconds') and kw.get('microseconds') and kw['seconds'].startswith('-')`.
- V1 status: left unchanged. The branch is unreachable under the current regex
  family but harmless. Removing it would be cleanup rather than a needed fix for
  the public issue.

## Proof-derived findings from `/verify`

- No blocking verification obstacle was found against the stated sign-placement
  spec.
- The formal model abstracts Python regex matching into parsed duration input
  shapes. This is a proof capability boundary, not a code bug, and is recorded
  in `SPEC_AUDIT.md`.
- Test removal is not recommended here because the proof was not
  machine-checked and the benchmark forbids editing tests.
