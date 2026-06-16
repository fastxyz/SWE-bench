# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt / issue | "`_foo = None  #: :meta public:`" with `.. automodule:: example` and `:members:` | `_foo` is in domain: module variable, private-looking name, source attribute documentation has `public` metadata, all-members mode is requested. | Encoded by claims `META-PUBLIC-VARIABLE` and `ATTR-VISIBILITY-PRECEDENCE`. |
| E2 | prompt / issue | "I expect `_foo` is shown on the built document, but not shown." | Expected postcondition: the member is kept and can be documented. | Encoded by `decision(true, true)`: keep the member and treat it as an attribute. |
| E3 | docs | "autodoc considers a member private if its docstring contains `:meta private:`" | Visibility metadata can force privacy independent of name spelling. | Encoded by `META-PRIVATE-VARIABLE`. |
| E4 | docs | "autodoc considers a member public if its docstring contains `:meta public:`, even if it starts with an underscore." | Visibility metadata can override the leading-underscore default. | Encoded by `META-PUBLIC-VARIABLE`. |
| E5 | source | `VariableCommentPicker.add_variable_comment()` stores `(basename, name) -> comment`; `ModuleAnalyzer.analyze()` exposes those comments as `attr_docs`. | Parser/analyzer already produce attribute documentation for variable comments; the fix should consume it rather than change parsing. | Used as a premise in `SPEC.md`; no parser change required. |
| E6 | source | `Documenter.add_content()` prefers `attr_docs` for attribute documentation and suppresses the runtime docstring for that object. | Attribute comments are the effective documentation source for variables and should supply visibility metadata for variables. | Drives Finding F-2 and obligation PO-3. |
| E7 | source | `Documenter.filter_members()` checks mocked, excluded, and special members before the attribute-doc branch, and sets `isattr = True` in the attribute-doc branch. | The metadata fix must preserve branch ordering and the `isattr` output needed by `DataDocumenter`. | Encoded by frame obligations PO-4 and PO-6. |
| E8 | public tests | Existing public tests cover `:meta public:` and `:meta private:` in function docstrings. | The existing docstring metadata behavior must remain intact. | Encoded by `DOCSTRING-PUBLIC-FRAME` and `META-PRIVATE-VARIABLE`. |
