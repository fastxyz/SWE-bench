# Public Evidence Ledger

Status: constructed, not machine-checked.

I-1. `benchmark/PROBLEM.md`: "Migration import ordering violates coding style
and isort defaults" means generated migration imports must satisfy the named
style-ordering rule.

I-2. `benchmark/PROBLEM.md`: "Place all import module statements before from
module import objects in each section" imposes the ordering property that plain
imports precede from-imports.

I-3. `benchmark/PROBLEM.md`: the desired example orders `import datetime`,
`import time`, then `from django.db import migrations, models`; this is the
concrete witness claim.

I-4. `benchmark/PROBLEM.md`: the public hint calls the repair a "small tweak"
and rejects complicated full-isort compatibility; this limits the frame.

I-5. `repo/django/db/migrations/writer.py` and
`repo/django/db/migrations/serializer.py`: generated import strings use the
forms `import <module>` and `from <module> import <objects>`; this supplies the
domain for the sort key.
