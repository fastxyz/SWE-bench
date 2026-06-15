# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "SplitArrayField with BooleanField always has widgets checked after the first True value." | Later split-array entries must not inherit a generated `checked` flag from an earlier true value. | Encoded by PO3 and the reproduction claim. |
| E2 | `benchmark/PROBLEM.md` | "Once this occurs every widget initialized after that defaults to checked even though the backing data may be False." | For backing value `False` with no explicit checked attr, the subwidget attrs must not contain generated `checked`. | Encoded by PO3. |
| E3 | `benchmark/PROBLEM.md` | "This is caused by the CheckboxInput widget's get_context() modifying the attrs dict passed into it." | `CheckboxInput.get_context()` must not mutate caller-owned attrs while computing returned context attrs. | Encoded by PO2. |
| E4 | `repo/django/forms/widgets.py` | `# if the checkbox should be checked for that value.` | `check_test(value)` controls generated checked state. | Encoded by PO1 and PO2. |
| E5 | `repo/django/forms/widgets.py` | `Widget.get_context()` returns attrs from `self.build_attrs(self.attrs, attrs)`. | The base widget builds returned attrs rather than requiring mutation of input attrs. | Supports the no-mutation frame condition. |
| E6 | `repo/django/contrib/postgres/forms/array.py` | `SplitArrayWidget.get_context()` passes `final_attrs` to each child widget in a loop. | The child widget must not contaminate `final_attrs`; otherwise later iterations observe the wrong state. | Encoded by PO3. |
| E7 | Public API shape | `get_context(self, name, value, attrs)` signatures are unchanged. | Existing callers and overrides remain compatible. | Encoded by PO5. |

No hidden tests, benchmark results, upstream patch knowledge, or internet sources were used.
