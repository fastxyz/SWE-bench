# Public Evidence Ledger

| ID | Source | Quoted evidence | Obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "`admin.E108` is raised on fields accessible only via instance." | Metadata-resolved fields remain valid even if model class attribute access fails. |
| E2 | `benchmark/PROBLEM.md` | "`only return an E108 in the case both of them fail`" | `E108` requires all relevant resolution paths to fail. |
| E3 | `benchmark/PROBLEM.md` | "`If either of those means ... are successful then we need to check if it's a ManyToMany.`" | Successful field/model-attribute resolution must still run the `ManyToManyField` check. |
| E4 | `repo/docs/ref/contrib/admin/index.txt` | "`There are four types of values that can be used in list_display`" | The accepted categories are model field, callable, `ModelAdmin` method/attribute, and model method/attribute. |
| E5 | `repo/docs/ref/contrib/admin/index.txt` | "`ManyToManyField` fields aren't supported" | `ManyToManyField` items produce `admin.E109`. |
| E6 | `repo/docs/ref/contrib/admin/index.txt` | "interpret every element ... in this order: A field of the model. A callable. ... `ModelAdmin` ... model attribute." | Model field metadata lookup has precedence over same-named admin/model fallback. |
| E7 | `repo/tests/modeladmin/test_checks.py` | Missing field expects `admin.E108`; `users` ManyToMany expects `admin.E109`; valid field/method/callable case is valid. | Preserve existing check outputs for representative public cases. |
| E8 | `repo/django/contrib/admin/utils.py` | `lookup_field()` calls `_get_non_gfk_field()` before callable/admin/model attribute fallback. | Validation should be compatible with runtime field-first interpretation. |

