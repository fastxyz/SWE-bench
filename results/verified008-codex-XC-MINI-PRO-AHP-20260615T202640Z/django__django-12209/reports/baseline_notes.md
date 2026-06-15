# Baseline Notes

## Root cause

`Model._save_table()` unconditionally applies the primary-key-default save optimization for newly constructed model instances. When a model's primary key field has a Python default, Django assigns that default during `Model.__init__()`, so `_save_table()` sees a non-`None` primary key even when the caller didn't explicitly provide one.

The optimization then sets `force_insert = True` for any new instance whose primary key field has a default. That is correct for ordinary object creation because it avoids an unnecessary UPDATE before the INSERT, but it changes raw deserialization saves. Fixture loading calls `Model.save_base(..., raw=True)`, and fixtures often contain explicit primary keys that should update existing rows when loaded repeatedly. Because the optimization forced an INSERT in this raw path, reloading such a fixture attempted to insert an existing primary key instead of trying an UPDATE first.

## Files changed

`repo/django/db/models/base.py`

Added `not raw` to the `_save_table()` condition that skips the UPDATE for new instances with primary-key defaults. Raw saves now keep the historical update-then-insert behavior, which allows deserialized fixture rows with explicit primary keys to update existing objects. Non-raw saves still use the one-query INSERT optimization for newly constructed objects with primary-key defaults.

`reports/baseline_notes.md`

Recorded the root cause, changed file, assumptions, and rejected alternatives required by the benchmark task.

## Assumptions and alternatives considered

I assumed the intended fix is the compromise described in the public discussion: preserve the primary-key-default optimization for normal saves, but disable it for raw fixture/deserialization saves. This directly addresses the `loaddata` regression called out in the issue.

I considered changing the condition to require `not pk_set`, but rejected it because Django has already assigned Python defaults by the time `_save_table()` runs. For primary-key defaults such as `UUIDField(default=uuid4)`, `pk_set` is true for both `Sample()` and `Sample(pk=existing_pk)`, so that change would effectively disable the optimization for the common case it was introduced to improve.

I also considered adding new instance state to track whether the primary key was explicitly supplied to `Model.__init__()`. That could distinguish normal `Sample()` from `Sample(pk=existing_pk)`, but it would be a broader construction-semantics change with more risk around positional arguments, deferred loading, model inheritance, and direct `pk` property assignment. The issue discussion notes that Django did not already track this information, and the raw-save guard fixes the fixture-loading regression without adding that new state.

No tests were run, per the benchmark instructions.
