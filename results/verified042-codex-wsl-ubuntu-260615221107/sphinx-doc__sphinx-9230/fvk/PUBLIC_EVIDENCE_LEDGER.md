# Public Evidence Ledger

| ID | Source | Quoted Evidence | Semantic Obligation | Status |
|---|---|---|---|---|
| E1 | issue | `:param dict(str, str) opc_meta: (optional)` | This exact inline typed field is in domain. | Encoded in PO1 and K claims C1/C2. |
| E2 | issue | incorrectly rendered as `str) opc_meta (dict(str,)` | A split at the first whitespace inside `dict(str, str)` is buggy. | Finding F1; V1 removes this mechanism. |
| E3 | issue | expected `opc_meta (dict(str,str))` | The parameter name must be `opc_meta`; the whole `dict(...)` expression is the type. | Encoded in PO1. |
| E4 | public test | `:param str name:` asserted as name `name`, type `str` | Single-word inline typed params must remain supported. | Encoded in PO2 and K claim C3. |
| E5 | public test | `:param items:` plus `:type items: Tuple[str, ...]` | Separate type fields with comma-space type expressions must remain supported. | Encoded as frame obligation PO3. |
| E6 | public docs | `Container types such as lists and dictionaries can be linked automatically` with `:type mapping: dict(str, int)` | Container type expressions with comma-space are meaningful Sphinx type expressions. | Supports PO1 type preservation. |
| E7 | public docs | `combine parameter type and description, if the type is a single word` | Old docs under-specify inline type expressions. | Finding F2; not allowed to veto E1-E3. |
| E8 | source/API audit | `modify_field_list` and `augment_descriptions_with_types` infer whether `:param ...:` already has a type | Autodoc annotation merging must identify the same final parameter name as docfield rendering. | Encoded in PO4 and K claims C4/C5. |
| E9 | task instruction | `Do not modify any test files` and no execution environment | Tests must remain untouched; proof is constructed only. | Encoded in PO6 and PROOF.md commands. |
