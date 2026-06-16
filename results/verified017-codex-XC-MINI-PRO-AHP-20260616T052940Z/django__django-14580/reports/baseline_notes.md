# Baseline Notes

## Root Cause

`django.db.migrations.serializer.TypeSerializer` special-cased `models.Model` by
serializing it as the string `models.Model`, but it returned no import for that
name. Most generated migrations still received `from django.db import models`
from serialized fields, but a model with only custom fields and custom bases can
reach `models.Model` in `bases` without any other serializer adding the models
import. The migration writer then emitted `models.Model` in the migration body
without binding `models`, causing `NameError` when the migration module was
loaded.

## Changed Files

`repo/django/db/migrations/serializer.py`

Updated the `models.Model` special case in `TypeSerializer.serialize()` to
return `from django.db import models` along with the existing `models.Model`
serialization string. This lets `MigrationWriter` merge the import into
`from django.db import migrations, models`, matching how other Django model
references are handled.

`reports/baseline_notes.md`

Added this report describing the root cause, the source change, assumptions, and
rejected alternatives.

## Assumptions and Alternatives Considered

I assumed the generated representation `models.Model` is intentional and should
remain stable for migration output compatibility. The bug is not the string that
is emitted, but the missing import metadata returned with it.

I considered changing `MigrationWriter` to detect literal `models.Model` usage in
rendered operation strings, but rejected that because imports are already owned
by serializers and string scanning would be broader and less reliable.

I considered serializing the base as `django.db.models.Model` instead, but that
would require a different import shape and would be a less targeted change than
teaching the existing special case to report the import it already depends on.

No tests were run, in accordance with the task instructions.
