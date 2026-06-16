# Public Evidence Ledger

Status: constructed for FVK audit, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | Prompt issue | "Instance variables link to other variables of the same name in the project" | The defect is automatic linking from an instance/class variable description to a same-name object. | Encoded in SPEC and FINDINGS. |
| E2 | Prompt issue | "the document of the instance variable will link to the other occurrence of a variable under the same name" | Same-name objects elsewhere are not valid targets for the field label. | Encoded in no-xref claim. |
| E3 | Prompt issue | "`somepackage::Foo.somename` ... could be completely unrelated to `somepackage.somename`" | A same-module module variable is also an invalid automatic target, not only cross-package fuzzy targets. | Rejects resolver-only fuzzy narrowing as incomplete. |
| E4 | Prompt issue | "Expected behavior: That the class variable documentation not be linked to any other." | Variable documentation field labels should render without implicit object links. | Encoded in no-xref claim. |
| E5 | Prompt issue | "the user can decide to document it as such with a simple reference ... `see :const:`somename``" | Explicit references remain the opt-in mechanism for linking related variables. | Encoded as frame condition. |
| E6 | Public docs | `var`, `ivar`, `cvar`: "Description of a variable." | Public docs describe variable fields as descriptions, not link-creating roles. | Supports V1. |
| E7 | Public docs | `vartype`: "Type of a variable. Creates a link if possible." | Type links must be preserved. | Encoded in type-link preservation claim. |
| E8 | Source implementation | `Field.make_xref()` returns plain content when `rolename` is falsey. | Removing a field's `rolename` prevents creation of `pending_xref`. | Used as implementation transition. |
| E9 | Source implementation | `PyXrefMixin.make_xref()` marks field xrefs `refspecific`; `PythonDomain.find_obj()` then tries class, module, exact, and suffix matches. | A variable field with `rolename='obj'` can reach unrelated objects if no same-class object exists. | Root-cause mechanism. |
| E10 | Source implementation | V1 `PyTypedField('variable', ...)` no longer passes `rolename='obj'`; it keeps `typerolename='class'`. | V1 blocks field-label xrefs while preserving type xrefs. | Confirmed. |
