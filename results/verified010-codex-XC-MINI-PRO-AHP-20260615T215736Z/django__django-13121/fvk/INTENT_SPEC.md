# Intent Spec

Status: constructed for FVK audit, not machine-checked.

## Public intent obligations

1. Duration-only arithmetic on backends without native duration fields must
   return a duration value in the storage representation expected by
   `DurationField` converters: integer microseconds.

2. The concrete reported case is in scope:
   `F('estimated_time') + datetime.timedelta(1)` in an annotation on SQLite and
   MySQL must evaluate without converter failure and yield a `timedelta`.

3. The intended family is valid duration addition and subtraction, not
   multiplication or division. Duration-only `+` and `-` include operands whose
   output is a `DurationField`, `timedelta` literals wrapped as `DurationValue`,
   explicit `Value(..., output_field=DurationField())`, and Django temporal
   subtraction expressions (`DateField - DateField`, `DateTimeField -
   DateTimeField`, `TimeField - TimeField`) that compile to durations.

4. Mixed date/time plus duration arithmetic must keep the existing backend
   interval/date-time handling. Examples include `DateTimeField +
   DurationField`, `DateTimeField + timedelta`, and `DateField -
   DurationField`.

5. The fix must not change public APIs, model field storage format, test files,
   or native-duration backend behavior.

## Default-domain assumptions

- Python and database integer arithmetic over stored microseconds is exact for
  values in Django's supported duration range.
- Partial correctness is the FVK target here. SQL execution, termination, and
  backend parser acceptance are not machine-checked in this session.
