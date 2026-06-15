# Formal Spec English

Status: constructed, not machine-checked.

## K model vocabulary

The K model represents parsed duration input shapes rather than raw Python
strings. This is intentional: the audited property is sign placement after the
standard regex has classified the input.

- `stdNoDays(sign, hours, minutes, seconds, micros)` represents a standard
  duration with no day component.
- `stdDays(days, timeSign, hours, minutes, seconds, micros)` represents a
  standard duration with a day component and a possible additional time sign.
- `stdInternalSign` represents a standard-looking value with a sign after a
  colon, such as `00:-01:-01` or `-01:-01`.
- `tdUs(n)` represents a `datetime.timedelta` whose total duration is `n`
  microseconds.
- `none` represents `parse_duration()` returning `None`.

## Claims

1. `STD-NODAYS-POS`: a no-day standard duration with no leading minus returns
   the positive time value.
2. `STD-NODAYS-NEG`: a no-day standard duration with a leading minus returns
   the negative of the entire time value, including fractional seconds.
3. `STD-DAYS-PRESERVE`: a standard duration with a day component and no
   additional time sign returns `days + positive_time`.
4. `STD-DAYS-SIGNED-TIME-INVALID`: a standard duration with a day component and
   another minus before the time value is invalid.
5. `STD-INTERNAL-SIGN-INVALID`: a standard value with a sign after a colon is
   invalid.
6. `REPORTED-HMS`: `-00:01:01` maps to negative 61 seconds.
7. `REPORTED-MS`: `-01:01` maps to negative 61 seconds.

These claims are partial-correctness claims over the modeled parser fragment.
They do not prove termination because the modeled transitions are single-step
rewrites and termination is not the issue under audit.
