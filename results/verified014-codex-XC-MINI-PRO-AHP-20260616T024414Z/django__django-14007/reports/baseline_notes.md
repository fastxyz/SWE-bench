# Baseline Notes

## Root cause

`SQLInsertCompiler.execute_sql()` fetched values for `returning_fields` directly
from backend insert helpers and returned them to `Model.save()` and
`QuerySet.bulk_create()` without applying database converters. Regular query
paths call `SQLCompiler.get_converters()` and `SQLCompiler.apply_converters()`,
which includes both backend converters and field converters such as
`from_db_value()`. The insert path skipped that step, so a custom `AutoField`
subclass with `from_db_value()` received the raw database integer after
`create()` or `bulk_create()`.

## Files changed

`repo/django/db/models/sql/compiler.py`

The insert compiler now stores returned insert rows in a local variable, builds
converter-compatible column expressions from the fields that were actually
returned, applies the normal converter pipeline, and returns the converted
rows. The fallback path for backends without insert `RETURNING` only converts
the primary key value because that is the only value `last_insert_id()` returns.
Converted rows are materialized as tuples to preserve the previous
list-of-row-tuples shape expected by callers.

## Assumptions and alternatives

I assumed the correct layer for the fix is the compiler rather than the model
assignment code because both `Model.save()` and `QuerySet.bulk_create()` obtain
their returned insert values from `_insert()`. Applying converters there keeps
all insert-returning consumers consistent.

I considered converting values in `Model._save_table()` and
`QuerySet.bulk_create()`, but rejected that because it would duplicate converter
logic and still leave any other private insert caller receiving raw values.

I used `field.get_col(self.query.get_meta().db_table)` instead of passing raw
fields to `get_converters()` because backend converters expect expression
metadata such as `output_field`, and some backends inspect expression-level
field properties.

No tests or project code were run, per the task constraints.
