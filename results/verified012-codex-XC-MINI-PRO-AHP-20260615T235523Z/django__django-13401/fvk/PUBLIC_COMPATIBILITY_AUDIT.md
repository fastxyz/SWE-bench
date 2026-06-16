# Public Compatibility Audit

Status: constructed, not machine-checked.

Changed public symbols:

- `django.db.models.fields.Field.__eq__(self, other)`
- `django.db.models.fields.Field.__lt__(self, other)`
- `django.db.models.fields.Field.__hash__(self)`

Compatibility results:

| Symbol | Signature changed? | Return shape changed? | Public compatibility status |
| --- | --- | --- | --- |
| `Field.__eq__` | No | Still returns `bool` for `Field`, `NotImplemented` otherwise. | Compatible; semantics intentionally stricter for different owners. |
| `Field.__lt__` | No | Still returns `bool` for `Field`, `NotImplemented` otherwise. | Compatible; preserves counter-first order and adds only equal-counter tie-breaking. |
| `Field.__hash__` | No | Still returns an integer hash. | Compatible with new equality. Hash now includes model owner, as requested by public intent. |

Callsite/override audit:

- `Options.add_field()` uses `bisect.insort()` and therefore relies on
  `Field.__lt__`; V1 preserves counter-first ordering for all different-counter
  cases.
- Abstract inheritance uses `copy.deepcopy(field)` and then
  `new_class.add_to_class()`, which calls `contribute_to_class()` and assigns
  `field.model` before `_meta.add_field()` inserts the field.
- No public subclass override of these comparison methods was found in
  `repo/django/db/models/fields/`.

Residual compatibility note:

Including `model` in the hash means an unattached field's hash can differ after
it is attached to a model. The issue explicitly asks for hash adjustment to
match owner-sensitive equality. The audited public use case retrieves fields
from `_meta` after model attachment, where the owner is stable.
