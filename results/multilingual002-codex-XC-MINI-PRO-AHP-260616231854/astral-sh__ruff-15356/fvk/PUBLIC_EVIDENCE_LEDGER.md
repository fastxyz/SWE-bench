# Public Evidence Ledger

| ID | Source | Evidence | Semantic Obligation | Status |
|---|---|---|---|---|
| E-01 | prompt | "False positive of E252, double output for each occurence" | The reported `E252` diagnostics are wrong for the reproducer. | Encoded in SPEC and K claim `issue E252 branch false`. |
| E-02 | prompt | `type MyType = Annotated[...]` with no `[T]` before the alias assignment | The alias has no explicit type-parameter list; RHS brackets must not be classified as type parameters. | Encoded in PO-01, PO-02, PO-03. |
| E-03 | prompt | Diagnostics point at `min_length=4`, `max_length=7`, `pattern=...` inside `pydantic.Field(...)` | Keyword-argument equals inside the alias value must not take the `MissingWhitespaceAroundParameterEquals` path. | Encoded in PO-06 and finding F-01. |
| E-04 | source comment/rule docs | `MissingWhitespaceAroundParameterEquals` docs describe annotated function parameters. | Annotated function parameter behavior is a frame condition. | Encoded in PO-04 and K function-frame claim. |
| E-05 | public fixture | `pep_696_bad[A=int, ...]` fixture says type parameters should receive E25-family diagnostics. | Actual type-parameter defaults must still be classified as type parameters. | Encoded in PO-05 and K type-param claim. |
| E-06 | implementation | `whitespace_around_named_parameter_equals` selects E252 when `definition_state.in_type_params()` is true. | Correctness reduces to preserving the exact in-type-params state at the relevant equals token. | Encoded in mini-K observable `isE252MissingBranch`. |
| E-07 | implementation | `DefinitionState` is private to logical-line checks. | Public API compatibility risk is low if no signatures or public data formats change. | Encoded in compatibility audit. |
