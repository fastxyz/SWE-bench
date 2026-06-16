# PROOF OBLIGATIONS

Status: constructed, not machine-checked.

PO-1, pipe union splitting:
For type atoms `A` and `B`, `A | B` must produce `xref(A)`, literal pipe
delimiter text, and `xref(B)`.  Proven by the delimiter regex alternative
`\s*\|\s*` and the `make_xrefs()` atom/delimiter loop.

PO-2, optional pipe whitespace:
For type atoms `A` and `B`, the pipe delimiter family includes `A|B`, `A |B`,
`A| B`, and `A | B`.  This is a conservative extension of IE-1 based on the
operator-like syntax; the regex alternative uses optional whitespace on both
sides.

PO-3, type atom cross-reference preservation:
Each non-delimiter segment still calls `self.make_xref(...)` with the existing
role, domain, inner node, content node, and environment.  `None` keeps the
existing Python-domain `obj` role special case in `PyField` and `PyTypedField`.

PO-4, existing delimiter frame:
The pre-existing delimiter families must remain unchanged: brackets,
parentheses, commas, optional `or` after punctuation, standalone word `or`, and
ellipsis.  The V1 patch only inserted a new alternative in the same regex.

PO-5, separate parameter type fields:
For `:param name:` plus `:type name: A | B`, `DocFieldTransformer` stores the
single text type body and `TypedField.make_field()` calls `make_xrefs()` on it.

PO-6, inline parameter type fields:
For `:param A | B name:`, `DocFieldTransformer` splits the final word as the
argument name and stores `A | B` as a text type body, so the same splitter is
used.

PO-7, variable and return type fields:
For `:vartype name: A | B`, `PyTypedField` uses the same splitter.  For
`:rtype: A | B`, `PyField` uses `bodyrolename='class'` and the same
`PyXrefMixin.make_xrefs()` implementation.

PO-8, attribute directive option path:
For `.. py:attribute:: name` with a `:type:` option, no V1 edit is required
because `PyAttribute.handle_signature()` already calls `_parse_annotation()`,
whose `ast.BitOr` branch emits pipe punctuation between parsed annotation
operands.

PO-9, non-text type content frame:
When collected type content is not a single `nodes.Text`, `TypedField` appends
the existing node content unchanged and never calls `make_xrefs()` on it.

PO-10, domain compatibility:
The change must not affect generic `TypedField` or non-Python domains.  This is
discharged structurally because the only source edit is inside the Python-domain
`PyXrefMixin`.

PO-11, honesty gate:
Proof artifacts and commands are constructed only.  No `kompile`, `kast`,
`kprove`, Python, or test command may be treated as having run.
