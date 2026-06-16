# Intent Spec

Status: intent-only; written before accepting candidate behavior as correct.

1. Generated migration files must be valid Python modules.

2. If generated migration code contains `models.Model`, the generated imports
   must bind `models`.

3. The presence of `from django.db import models` must not depend on unrelated
   fields or managers. A `bases` tuple alone can create the need for the import.

4. The existing migration serialization contract is a pair:
   serialized text plus the imports required by that text.

5. The fix must preserve existing serializer behavior for `type(None)`, built-in
   types, custom importable types, fields, managers, and operation writing.

6. The fix must preserve public APIs and must not modify tests.
