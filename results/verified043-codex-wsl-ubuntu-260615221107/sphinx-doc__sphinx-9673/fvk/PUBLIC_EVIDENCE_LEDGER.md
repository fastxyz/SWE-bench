# Public Evidence Ledger

Status: constructed for FVK audit, not machine-checked.

| Id | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-1 | `benchmark/PROBLEM.md` | "`autodoc_typehints_description_target = \"documented\"` combined with the Napoleon plugin" | Audit the documented-description branch, not the `"all"` branch alone. | Encoded by `I-1`, `PO-1`, `PO-5`. |
| E-2 | `benchmark/PROBLEM.md` | "The return types were missing from the resulting documentation." | A documented return with a return annotation must receive visible return type information. | Encoded by `I-4`, `PO-3`. |
| E-3 | `benchmark/PROBLEM.md` | "As the return is specified, the return type should be present" | Presence of a return description is the trigger in `"documented"` mode. | Encoded by `I-1`, `PO-3`. |
| E-4 | `benchmark/PROBLEM.md` public hint | "return type field is not generated when the info-field-list uses `returns` field instead of `return`" | `returns` must be treated as a return description for type injection. | Encoded by `I-2`, `I-4`, `PO-2`. |
| E-5 | `benchmark/PROBLEM.md` public hint | "napoleon generates a `returns` field internally" | Do not fix by changing Napoleon output; fix autodoc's recognition of that field. | Encoded by `I-3`, `I-8`, `F-2`. |
| E-6 | `repo/sphinx/domains/python.py` | `Field('returnvalue', ..., names=('returns', 'return'))` | Python domain accepts both spellings as the same return-value field. | Encoded by `I-2`, `PO-2`. |
| E-7 | `repo/sphinx/ext/napoleon/docstring.py` | `_parse_returns_section()` emits `:returns:` | The issue path reaches autodoc with field name `returns`. | Encoded by `I-3`, `PO-5`. |
| E-8 | `repo/sphinx/ext/autodoc/typehints.py` | Existing code adds `rtype` only when `'return' in has_description and 'return' not in has_type`. | The scan must set the canonical return-description marker for both aliases. | Encoded by `PO-2`, `PO-3`. |
| E-9 | `repo/tests/test_ext_autodoc_configs.py` | Existing public test with `:return:` expects `Return type` in documented mode. | The `return` spelling remains supported. | Encoded by `PO-2`, `PO-7`. |
| E-10 | `repo/sphinx/directives/__init__.py` | `object-description-transform` is emitted before `DocFieldTransformer(...).transform_all`. | Autodoc sees raw field names such as `returns` before domain field transformation. | Encoded by `PO-5`. |
