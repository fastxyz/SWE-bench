# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | `benchmark/PROBLEM.md` | "Enumeration Types are not usable in templates." | Choices enum classes must be usable as template context values. | Encoded in `SPEC.md`, `choices-template-spec.k`, PO-001 through PO-003. |
| E-002 | `benchmark/PROBLEM.md` | "`{% if student.year_in_school == YearInSchool.FRESHMAN %}`" | A dotted lookup through an enum class must reach the enum member. | Encoded in claim `TEMPLATE-ENUM-MEMBER-LOOKUP`. |
| E-003 | `benchmark/PROBLEM.md` | "YearInSchool, being a class, is callable, and Django Templates always call callables with no arguments." | The failure mechanism is the template callable gate on the intermediate enum class. | Encoded in finding F-001 and the unmarked-class diagnostic claim. |
| E-004 | `benchmark/PROBLEM.md` | "The easy solution would be to declare do_not_call_in_templates = True on the various Choices classes." | The fix mechanism is the existing template do-not-call marker on choices classes. | Encoded in PO-001 and the V1 source change. |
| E-005 | `repo/django/template/base.py` | `if getattr(current, 'do_not_call_in_templates', False): pass` | A callable value with this marker is preserved instead of called. | Encoded in PO-002. |
| E-006 | `repo/tests/template_tests/test_callables.py` | "the template system will not try to call our doodad. We can access its attributes as normal" | The marker's public behavior is "do not call, then allow attribute lookup." | Encoded in PO-002 and PO-003. |
| E-007 | `repo/django/db/models/enums.py` | `ChoicesMeta.__new__()` creates the enum class and then installs `label` after class creation. | Post-creation assignment is an established local pattern for non-member class attributes on choices enum classes. | Encoded in PO-004. |
| E-008 | `repo/django/db/models/__init__.py` and `repo/django/db/models/enums.py` | `Choices`, `IntegerChoices`, and `TextChoices` are exported public model symbols. | The compatibility audit must check that their signatures and exports are unchanged. | Encoded in `PUBLIC_COMPATIBILITY_AUDIT.md` and PO-005. |
