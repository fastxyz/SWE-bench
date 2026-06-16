# Public Evidence Ledger

| ID | Source | Evidence | Semantic Obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "DEFAULT_AUTO_FIELD subclass check fails for subclasses of BigAutoField and SmallAutoField." | Accept subclasses of both compatibility roots. |
| E2 | `benchmark/PROBLEM.md` | `class MyBigAutoField(models.BigAutoField)` triggers "must subclass AutoField." | The shown ValueError is the bug, not desired behavior. |
| E3 | `benchmark/PROBLEM.md` | Fix can be in `AutoFieldMeta.__subclasscheck__` by allowing subclasses of `_subclasses`. | The metaclass compatibility surface is the repair target. |
| E4 | `repo/django/db/models/fields/__init__.py` | `_subclasses` returns `(BigAutoField, SmallAutoField)`. | The roots are exactly Big and Small auto fields. |
| E5 | `repo/django/db/models/fields/__init__.py` | Comment says the metaclass maintains backward inheritance compatibility. | Preserve direct `AutoField` behavior and compatibility. |
| E6 | `repo/django/db/models/options.py` | `_get_default_pk_class()` uses `issubclass(pk_class, AutoField)`. | The observable is the subclass-check truth value. |
| E7 | `repo/tests/model_options/test_default_pk.py` | `TextField` default auto field raises "must subclass AutoField." | Non-auto fields remain rejected. |
| E8 | `repo/tests/model_options/test_default_pk.py` | Nonexistent and `None` defaults raise `ImproperlyConfigured`. | Import/empty handling remains separate. |
| E9 | `repo/tests/model_fields/test_autofield.py` | Concrete Big/Small auto fields satisfy `issubclass(..., AutoField)`. | Existing concrete compatibility roots still pass. |
| E10 | `repo/tests/custom_pk/fields.py` | `class MyAutoField(models.BigAutoField)` exists publicly. | Custom Big auto-field subclasses are plausible public field classes. |
