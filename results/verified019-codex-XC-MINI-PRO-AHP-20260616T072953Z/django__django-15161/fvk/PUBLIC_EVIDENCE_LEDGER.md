# PUBLIC EVIDENCE LEDGER

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "`F()` deconstructed to: `django.db.models.expressions.F()` ... changed it to deconstruct to `django.db.models.F()`." | Short root path is the intended form when the class is available as `django.db.models.X`. |
| E2 | `benchmark/PROBLEM.md` | "same technique can be applied to other expressions" | Apply the same exact-class `deconstructible(path=...)` mechanism to comparable expressions. |
| E3 | `repo/django/db/models/__init__.py` | Direct imports and `__all__` include `Case`, `Expression`, `Value`, etc. | These names are valid root import targets. |
| E4 | `repo/django/utils/deconstruct.py` | `if path and type(obj) is klass` | Custom path applies only to exact instances, preserving subclass fallback. |
| E5 | `repo/django/db/migrations/serializer.py` | `module == "django.db.models"` maps to `models.<name>`. | The shorter deconstruct path directly simplifies migration output. |
| E6 | `repo/django/db/models/expressions.py` | `Subquery(BaseExpression, Combinable)` and `Exists(Subquery)` have no decorator. | Adding `deconstruct()` to them is beyond path simplification. |

