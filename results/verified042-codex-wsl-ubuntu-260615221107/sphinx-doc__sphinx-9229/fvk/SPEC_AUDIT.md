# Spec Audit

| Formal English item | Intent match | Reason |
| --- | --- | --- |
| Data aliases with source comments show docs and suppress fallback. | Pass | Matches issue expectation for documented aliases and covers newer generic-alias routing. |
| Attribute aliases with source comments show docs and suppress fallback. | Pass | Same observable behavior at class scope; no contrary public intent. |
| Class aliases with source comments show docs, suppress fallback, and record dependency. | Pass | Covers Python 3.6-style routing implicated by `Dict`/`Callable`; dependency frame follows existing autodoc analyzer behavior. |
| Undocumented aliases keep fallback. | Pass | Issue only objects to fallback replacing documented alias docstrings; no public request to remove undocumented fallback. |

No formal claim is legacy-derived without public support. Visible tests that
expect documented aliases to include fallback are marked SUSPECT in
`fvk/FINDINGS.md`.
