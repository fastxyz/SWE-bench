# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

Target function: `django.utils.dateparse.parse_duration(value)`.

The audit focuses on the standard-duration branch because the GitHub issue is
about `standard_duration_re` and negative standard durations. ISO 8601 and
PostgreSQL interval parsing are frame conditions because V1 did not change
their regexes or arithmetic.

The formal model represents a parsed standard-duration shape rather than raw
Python regex execution. This abstraction is property-complete for the audited
axis: it distinguishes a leading sign, a sign after a day part, and a sign after
a colon, and it computes the signed duration value in total microseconds.

## Public intent ledger

See `fvk/PUBLIC_EVIDENCE_LEDGER.md` for the full ledger. The binding entries
are:

- E3: a leading `-` on a no-day standard duration negates the entire time
  value.
- E4/E5: signs after colons are invalid in standard duration strings.
- E6: positive standard formats and the other documented format families remain
  accepted.
- E7: signed day values emitted by Python/Django formatting keep signed-day
  semantics.
- E8: existing public tests for component-local signs in no-day negative
  standard durations are suspect legacy behavior and do not override E3-E5.

## Standard-duration contract

Let:

`TIME_US(H, M, S, U) = (((H * 60) + M) * 60 + S) * 1000000 + U`

where omitted hours or minutes are `0`, seconds are nonnegative digits, and
`U` is the padded/truncated microsecond value.

For the standard duration format:

1. No day component, no sign: return `timedelta(microseconds=TIME_US(...))`.
2. No day component, leading `-`: return
   `timedelta(microseconds=-TIME_US(...))`.
3. Day component, no time sign: return
   `timedelta(days=days) + timedelta(microseconds=TIME_US(...))`.
4. Day component plus an additional time sign: invalid standard duration,
   returning `None` unless a different documented format matches first.
5. Any sign after a colon in standard syntax: invalid, returning `None`.

## Code-to-spec mapping

- `standard_duration_re` now captures one optional `sign` before the standard
  time portion.
- `hours`, `minutes`, and `seconds` are unsigned in the standard regex.
- `parse_duration()` converts the captured sign into `sign * timedelta(**kw)`.
- The V1 guard rejects standard matches where a day component is followed by a
  second time sign.
- ISO 8601 and PostgreSQL matches still use their pre-existing regex-specific
  `sign` handling.

## Formal artifacts

- `fvk/mini-python-duration.k`: mini K semantics for parsed duration shapes.
- `fvk/parse-duration-spec.k`: K reachability claims for the standard duration
  sign-placement contract.
- `fvk/FORMAL_SPEC_ENGLISH.md`: English paraphrase of the claims.
- `fvk/SPEC_AUDIT.md`: adequacy comparison against `fvk/INTENT_SPEC.md`.
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`: signature, callsite, and format-family
  compatibility check.
