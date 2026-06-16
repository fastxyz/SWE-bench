# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | issue | "`autodoc_type_aliases` doesn't work when `autodoc_typehints` is set to `description`" | Description-mode type rendering must honor aliases. | Encoded in `SPEC.md` and `autodoc-typehints-spec.k`. |
| E2 | issue | `autodoc_type_aliases = {'JSONObject': 'types.JSONObject'}` | The raw postponed annotation name `JSONObject` maps to rendered target `types.JSONObject`. | Encoded. |
| E3 | issue | Observed: `Dict[str, Any]`; expected: "`types.JSONObject` instead of `Dict[str, Any]` in both cases" | Expanding the alias in description fields is the bug; preserving the alias target is required for parameter and return. | Encoded; pre-fix display marked SUSPECT legacy behavior. |
| E4 | docs | `autodoc_typehints` value `description` means "Show typehints as content of function or method" | The observable in scope is generated field content, not the visible signature. | Encoded. |
| E5 | docs | `autodoc_type_aliases` "is used to keep type aliases not evaluated in the document" | Alias names must be resolved through the configured alias map before stringification. | Encoded. |
| E6 | public test | With `autodoc_type_aliases = {'myint': 'myint'}`, signature output contains `myint` for function and variable annotations. | The existing signature resolver is alias-aware and is the compatibility baseline. | Encoded as default-domain assumption. |
| E7 | implementation | Function/method documenters already call `inspect.signature(..., type_aliases=self.config.autodoc_type_aliases)`. | The correct resolver is available and already used by signature mode. | Used as implementation evidence for the source edit. |
| E8 | implementation | V1 `record_typehints()` now calls `inspect.signature(obj, type_aliases=app.config.autodoc_type_aliases)`. | The description-mode recorder uses the same alias-aware resolver before `typing.stringify()`. | Confirmed. |
| E9 | implementation | `merge_typehints()` gates on `app.config.autodoc_typehints == 'description'`; `modify_field_list()` copies recorded annotation strings into `type NAME` and `rtype` fields unless already present. | Once recording is alias-aware, merge preserves the corrected string into the user-visible fields. | Confirmed. |

## SUSPECT legacy evidence

The issue's displayed `Dict[str, Any]` output is explicitly the buggy behavior. It is
evidence for the failure mode and must not be preserved as a compatibility obligation.
