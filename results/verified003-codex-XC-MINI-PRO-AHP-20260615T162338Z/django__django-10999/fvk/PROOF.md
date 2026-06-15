# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## Adequacy gate

The intent spec requires a leading `-` on a no-day standard duration to negate
the whole time value and requires signs after colons to be invalid. The formal
claims in `parse-duration-spec.k` state exactly those obligations over a parsed
standard-duration model. `SPEC_AUDIT.md` marks every claim as passing against
`INTENT_SPEC.md`.

The only public-test conflict is the old component-sign expectation for
`-15:30` and `-1:15:30`. Per FVK's suspect-evidence rule, those tests do not
override the bug report because they encode the behavior the issue rejects.

## Symbolic proof sketch

### No-day positive standard durations

Starting state:

`<k> parseDuration(stdNoDays(pos, H, M, S, U)) </k>`

The `MINI-DURATION` semantics applies the positive no-day rule, under
`S >= 0` and `0 <= U < 1000000`, and rewrites in one step to:

`<k> tdUs(timeUs(H, M, S, U)) </k>`

This is the `STD-NODAYS-POS` postcondition.

### No-day negative standard durations

Starting state:

`<k> parseDuration(stdNoDays(neg, H, M, S, U)) </k>`

The negative no-day rule applies under the same component preconditions and
rewrites in one step to:

`<k> tdUs(0 -Int timeUs(H, M, S, U)) </k>`

This proves that the sign applies to the whole time expression, including
hours, minutes, seconds, and microseconds.

Concrete consequence:

- `timeUs(some(0), some(1), 1, 0) = 61000000`, so `-00:01:01` reaches
  `tdUs(-61000000)`.
- `timeUs(none, some(1), 1, 0) = 61000000`, so `-01:01` reaches
  `tdUs(-61000000)`.

### Standard durations with days

Starting state:

`<k> parseDuration(stdDays(D, pos, H, M, S, U)) </k>`

The day-preserving rule rewrites to:

`<k> tdUs(daysUs(D) +Int timeUs(H, M, S, U)) </k>`

This matches the signed-day semantics used by Python/Django duration strings,
including negative day values.

Starting state with a second time sign:

`<k> parseDuration(stdDays(D, neg, H, M, S, U)) </k>`

The invalid signed-time rule rewrites to:

`<k> none </k>`

This corresponds to V1's explicit guard for a standard match with both `days`
and a captured `sign`.

### Internal signs

Starting state:

`<k> parseDuration(stdInternalSign) </k>`

The invalid-internal-sign rule rewrites to:

`<k> none </k>`

This represents standard-looking strings with a sign after a colon, including
`00:-01:-01` and `-01:-01`.

## Mapping proof steps to V1 source

- The no-day `neg` rule maps to `standard_duration_re` capturing
  `(?P<sign>-?)` before unsigned time components and to
  `sign * datetime.timedelta(**kw)`.
- The internal-sign invalid rule maps to unsigned `hours`, `minutes`, and
  `seconds` groups in `standard_duration_re`.
- The signed-day invalid rule maps to the V1 guard before timedelta
  construction.
- The day-preserving rule maps to keeping `days` independently signed and
  adding `days + sign * timedelta(**kw)`.

## Machine-check commands, not executed

These commands are the emitted FVK reproduction commands. They were not run in
this benchmark session.

```sh
cd fvk
kompile mini-python-duration.k --backend haskell
kast --backend haskell parse-duration-spec.k
kprove parse-duration-spec.k
```

Expected machine-check result after a successful future run: `#Top`.

## Residual risk

- The proof is constructed rather than machine-checked.
- The mini K model abstracts raw Python regex matching into parsed input
  constructors. It is sufficient for sign-placement reasoning but not a full
  proof of Python `re`.
- Termination is not separately proved. The modeled parser transitions are
  single-step rewrites, and the production code has no loop in the audited
  branch.

## Test recommendations

Do not delete tests based on this proof in the current session. If the K claims
are machine-checked later, in-domain point tests for the modeled standard sign
placement become proof-subsumed. Tests for integration through forms/models,
overflow, ISO 8601, PostgreSQL intervals, and raw regex boundary coverage should
be kept because they are outside or broader than the formalized slice.
