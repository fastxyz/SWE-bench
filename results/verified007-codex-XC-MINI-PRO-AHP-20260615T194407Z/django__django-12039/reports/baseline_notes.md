# Baseline Notes

## Root Cause

`django.db.backends.ddl_references.Columns.__str__()` appended column suffixes directly to quoted column names. For index ordering suffixes produced by `Index.fields_orders`, this made descending indexes render as `"column"DESC` instead of `"column" DESC`.

`django.db.backends.ddl_references.IndexColumns.__str__()` handled PostgreSQL opclasses by always formatting the optional column suffix with a preceding space. `Index.fields_orders` supplies an empty string for ascending order, so an opclass without explicit ordering rendered with a trailing space, e.g. `"column" text_pattern_ops `.

## Files Changed

`repo/django/db/backends/ddl_references.py`

Changed column rendering so column names, opclasses, and suffixes are joined as separate SQL tokens only when the optional token is non-empty. This produces `"column" DESC`, preserves `"column"` when the suffix is empty, renders PostgreSQL opclasses as `"column" text_pattern_ops`, and renders descending opclass indexes as `"column" text_pattern_ops DESC`.

## Assumptions and Alternatives

I assumed `col_suffixes` entries are suffix tokens such as `DESC` or `''`, matching `Index.fields_orders`, rather than pre-spaced SQL fragments. The visible callers under `repo/django` follow that contract.

I considered changing `Index.create_sql()` to emit pre-spaced suffixes, but rejected it because that would leave `IndexColumns` still responsible for suppressing the trailing separator when opclasses are used with an empty suffix. Fixing the DDL reference rendering addresses both symptoms at the point where SQL text is assembled.

I also considered special-casing only `DESC`, but rejected it because the rendering helper is already designed to accept generic per-column suffixes. Joining non-empty SQL tokens is the narrower and more general fix for the whitespace problem.
