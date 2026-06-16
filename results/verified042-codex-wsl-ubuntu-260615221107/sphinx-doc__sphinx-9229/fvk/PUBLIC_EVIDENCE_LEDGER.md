# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation |
| --- | --- | --- | --- |
| E1 | prompt | "3 multiline docstrings for type aliases" | Source docstring-comments are in scope. |
| E2 | prompt | "For 1 ... correctly shown ... for 2 ... ignored" | More than one autodoc route must be audited. |
| E3 | prompt | "show the contents in the docstrings for all the type aliases instead of ... `alias of ...`" | Source docstring-comments suppress generated fallback for documented aliases. |
| E4 | prompt | Reduced example includes `Dict`, `Union`, and `Callable`. | The alias family includes Python 3.6-style class alias routing and generic-alias routing. |
| E5 | implementation | Parser records string expressions after assignments as comments. | Parser behavior is supporting evidence, not the bug locus. |
| E6 | implementation | Existing autodoc records analyzer sources as dependencies. | New source-comment lookup should preserve dependency tracking. |
| E7 | visible public tests | Some legacy expectations include docstring plus fallback. | SUSPECT where they conflict with E3. |
