# FINDINGS

Status: constructed, not machine-checked.

F-1, resolved primary defect:
Input `:type text: bytes | str` on the pre-fix splitter produced one target,
conceptually `xref("bytes | str")`, because `|` was not a delimiter.  Expected
from IE-1 and PO-1 is `xref("bytes")`, literal ` | `, and `xref("str")`.
V1 resolves this by adding `\s*\|\s*` to the delimiter regex.

F-2, no source-level gap found for the requested Python field family:
PO-5, PO-6, and PO-7 show the same splitter is used for separate parameter
types, inline parameter types, variable types, return types, and napoleon
keyword types.  This supports keeping V1 unchanged.

F-3, attribute wording is covered without another edit:
The issue mentions attributes.  Python attribute directive `:type:` options use
`_parse_annotation()`, whose AST handling already has an `ast.BitOr` branch.
Variable/instance-variable field lists use `:vartype:` and are covered by PO-7.
No additional source edit is justified by this audit.

F-4, compatibility frame holds:
PO-4, PO-9, and PO-10 show the patch does not remove existing delimiter
families, does not split non-text field content, and does not affect non-Python
domains.  The public substitution-style fixture remains outside the text
splitter path.

F-5, residual parser limitation, not a new V2 obligation:
The existing Python type-field splitter is regex-based and does not attempt to
parse full Python typing syntax with quoted literals.  Adding pipe support
continues that local design.  The public issue and docs require delimiter-based
linking, not a full annotation parser for all field-list type text.  Treat a
future request for quote-aware `Literal[...]` parsing as a separate enhancement.

F-6, proof status limitation:
The FVK proof is constructed but not machine-checked.  PO-11 blocks any claim
that `kprove` returned `#Top`, and blocks test removal.  This does not block the
source decision because the code change is directly derived from IE-1 and the
source audit obligations.
