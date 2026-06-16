# Public Compatibility Audit

Constructed, not machine-checked.

## Changed Symbol

- `repo/sphinx/domains/python.py::PyProperty.handle_signature`

## Compatibility Checks

| Surface | Status | Evidence |
| --- | --- | --- |
| Method signature | compatible | The method remains `handle_signature(self, sig: str, signode: desc_signature) -> Tuple[str, str]`. |
| Directive option schema | compatible | `PyProperty.option_spec` still accepts `type`, `abstractmethod`, and `classmethod`; no option names or value types changed. |
| Directive registration | compatible | `PyProperty` remains registered as the Python domain handler for `property`. |
| Return value | compatible | The method still returns `fullname, prefix` from `super().handle_signature(...)`. |
| Signode display text | compatible | The visible text still begins with `": "` followed by the annotation spelling; the node children now include parsed xref nodes. |
| Autodoc producer | compatible | `PropertyDocumenter` still emits `:type:` from the getter return annotation; no autodoc source was changed in V2. |
| Subclasses / overrides | compatible | Search found no subclass override of `PyProperty.handle_signature()` in `repo/sphinx` or public tests. |

No public compatibility issue blocks keeping V1.
