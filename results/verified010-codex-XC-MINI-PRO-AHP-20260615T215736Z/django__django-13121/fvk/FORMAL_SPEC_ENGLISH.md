# Formal Spec English

Status: constructed, not machine-checked.

## Claim paraphrases

1. `DURATION-FIELD-PLUS-LITERAL`: compiling `DurationField + timedelta` with
   connector `+` produces numeric stored-microsecond SQL.

2. `LITERAL-PLUS-DURATION-FIELD`: compiling `timedelta + DurationField` with
   connector `+` produces numeric stored-microsecond SQL.

3. `DURATION-FIELD-PLUS-DURATION-FIELD`: compiling
   `DurationField + DurationField` produces numeric stored-microsecond SQL.

4. `TEMPORAL-SUBTRACTION-PLUS-DURATION`: compiling
   `DurationField + (DateTimeField - DateTimeField)` produces numeric
   stored-microsecond SQL because the temporal subtraction is duration output.

5. `MIXED-DATETIME-PLUS-DURATION`: compiling
   `DateTimeField + DurationField` stays on the backend mixed
   date/time-duration path and formats the duration operand as an interval.

6. `MULTIPLY-STAYS-ON-BACKEND-DURATION-PATH`: compiling
   `DurationField * timedelta` does not use the duration-only numeric branch.

## Frame conditions

- No public API signatures change.
- No backend hook signatures change.
- No field storage format changes.
- No tests are edited.
