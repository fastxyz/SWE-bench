# Public Evidence Ledger

This ledger mirrors the entries in `SPEC.md`.

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E-001 | `benchmark/PROBLEM.md` | "`model_to_dict() should return an empty dict for an empty list of fields.`" | `fields=[]` returns `{}`. |
| E-002 | `benchmark/PROBLEM.md` | "`fields=[]` ... `because no fields were requested.`" | Empty list is a provided inclusion filter. |
| E-003 | `model_to_dict()` docstring | "`fields` is an optional list... If provided, return only the named." | `None` and a provided list have distinct meanings. |
| E-004 | `model_to_dict()` docstring | "`exclude` ... exclude the named ... even if they are listed in `fields`." | Exclude has precedence. |
| E-005 | source implementation | Field sequence uses concrete, private, and many-to-many fields. | Model a finite metadata field sequence. |
| E-006 | public hint | "fetch instance fields values without touching ForeignKey fields" | Skipped fields should not be read. |
| E-007 | source call path | `model_to_dict(instance, opts.fields, opts.exclude)` | ModelForm initialization shares the fixed behavior. |
