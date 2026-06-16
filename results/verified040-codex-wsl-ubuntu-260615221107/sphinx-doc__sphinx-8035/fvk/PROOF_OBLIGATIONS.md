# Proof Obligations

Status: constructed, not machine-checked.

| ID | Obligation | Evidence | Artifact / code location | Status |
| --- | --- | --- | --- | --- |
| PO-1 | `private-members` must parse comma-list arguments into a finite selector. | I1, I2, I4 | `autodoc-private-members-spec.k` parse CSV claim; `members_option()` | Discharged by V2 source and claim. |
| PO-2 | Bare `private-members` and `True` must still mean all private members. | I5, I6 | parse bare/true claims; `members_option()` | Discharged. |
| PO-3 | `ModuleDocumenter` and `ClassDocumenter` must register `private-members` with the list-capable converter. | I1, I4 | `repo/sphinx/ext/autodoc/__init__.py` option specs | Discharged. |
| PO-4 | Explicit private names must be merged into `members` when `members` is absent. | I4, I7 | merge absent claim; `merge_private_members_option()` | Discharged. |
| PO-5 | Explicit private names must augment finite `members` without duplicating names. | I4, I7, I9 | merge finite claim; `merge_members_option()` | Discharged. |
| PO-6 | `members is ALL` must stay ALL; finite private selection is enforced by filtering, not by replacing the gathered member set. | I3, I5 | merge all claim; filter list claims | Discharged. |
| PO-7 | In all-members mode, selected private documented members are kept and unselected private documented members are skipped. | I3 | keep selected/unselected claims; `filter_members()` private branch | Discharged. |
| PO-8 | Bare all-private selection keeps all eligible private documented members. | I5 | keep `selAll` claim; `filter_members()` private branch | Discharged. |
| PO-9 | Existing skip precedence is preserved: excluded and mocked members are skipped even if selected. | I8 | excluded/mock claims; unchanged branch order | Discharged. |
| PO-10 | Explicit private names in `members` remain keepable even without `private-members`. | I9 | explicit-members claim; `want_all == False` path | Discharged. |
| PO-11 | Source-documented private attributes are kept when selected. | Existing attr-doc behavior | attr-doc claim; attr-doc branch | Discharged. |
| PO-12 | Public docs must describe list arguments for `private-members`. | I10 | `repo/doc/usage/extensions/autodoc.rst` | V1 failed; V2 fixed. |
| PO-13 | No public API/override compatibility break is introduced. | Public compatibility audit | `PUBLIC_COMPATIBILITY_AUDIT.md` | Discharged for documented option values. |

No loop circularity is required for this fragment: the modeled merge recursion over selector lists is specified by functional rewrite rules over finite lists, and the production code uses ordinary Python iteration over finite option lists. Termination is not proved; this FVK pass establishes partial correctness of the decisions if the functions return.
