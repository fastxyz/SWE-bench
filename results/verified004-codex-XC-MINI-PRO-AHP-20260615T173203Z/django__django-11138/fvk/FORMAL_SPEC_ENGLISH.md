# Formal Spec English

Each item paraphrases a nontrivial K claim or formal obligation.

1. `MYSQL-NO-TZ`: If timezone support is disabled at Django level, MySQL datetime
   SQL conversion leaves the field expression unchanged.

2. `MYSQL-SAME-TZ`: If `USE_TZ` is true but the database source timezone equals
   the requested timezone, MySQL leaves the field expression unchanged.

3. `MYSQL-CONVERT`: If `USE_TZ` is true and source and target timezone names
   differ, MySQL emits a conversion whose source argument is the database
   connection timezone and whose target argument is the requested timezone.

4. `ORACLE-SAME-TZ`: If `USE_TZ` is true but source and target timezone names are
   equal, Oracle leaves the field expression unchanged.

5. `ORACLE-CONVERT`: If `USE_TZ` is true and source and target timezone names
   differ, Oracle emits a conversion from the database connection timezone to
   the requested timezone.

6. `SQLITE-DATE-NO-TZ`: If timezone support is disabled, SQLite date casting
   returns the date part of the stored wall-clock value with no timezone
   conversion.

7. `SQLITE-DATE-SAME-TZ`: If `USE_TZ` is true and source and target timezone
   names are equal, SQLite date casting returns the date part of the stored
   wall-clock value with no timezone conversion.

8. `SQLITE-DATE-CONVERT`: If `USE_TZ` is true and source and target timezone
   names differ, SQLite date casting first interprets the stored wall-clock
   value in the source timezone, converts it to the target timezone, and then
   returns that date part.

9. `SQLITE-ARITY`: SQLite datetime SQL generation and registered helper
   functions use matching argument counts and order for source and target
   timezone names.

10. `FAMILY-COVERAGE`: Cast-to-date, cast-to-time, extraction, and truncation
    operations all call the corrected backend conversion path, so the repair is
    not limited to the single `__date` example.

11. `COMPATIBILITY`: The public/virtual `datetime_*_sql()` operation signatures
    are unchanged, so callers and backend overrides keep the same call shape.
