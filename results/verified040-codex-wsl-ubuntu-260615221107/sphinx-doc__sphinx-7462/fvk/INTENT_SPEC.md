# Intent Specification

Status: constructed from public evidence only. Current implementation behavior is
listed only as an observation to audit, not as an oracle.

## Target

The audited unit is `sphinx.domains.python._parse_annotation()` and its nested
`unparse()` helper for annotation AST nodes. The observable result is the
ordered list of docutils/addnodes children used to render a Python signature
annotation.

## Required Behavior

I1. Empty tuple annotations are in domain.

Source: `benchmark/PROBLEM.md` reports a function returning `Tuple[()]` and says
the docs should be built with valid type annotations.

Obligation: parsing and rendering `Tuple[()]` must not raise
`IndexError`; it must preserve the empty tuple literal `()` inside the
subscript.

I2. Existing supported non-empty annotation forms remain unchanged.

Source: public tests in `repo/tests/test_domain_py.py` cover `List[int]`,
`Tuple[int, int]`, and `Callable[[int, int], int]`.

Obligation: non-empty list and tuple AST nodes keep their current punctuation and
comma behavior: no trailing comma token and no extra parentheses around normal
tuple subscripts.

I3. Empty list literals in supported annotation syntax are in the same delimiter
family.

Source: public tests show the parser intentionally supports list literal syntax
inside annotations via `Callable[[int, int], int]`. The issue explicitly names an
empty boundary bug in the same separator-removal idiom.

Obligation: for a supported `ast.List` with zero elements, such as the inner
`[]` in `Callable[[], int]`, the renderer must preserve both list delimiters as
`[` and `]`, and must not consume either delimiter as if it were a trailing
separator.

I4. Cross-reference conversion remains a frame condition.

Source: current `_parse_annotation()` converts `nodes.Text` names into Python
pending xrefs after unparsing, and public tests assert xref nodes for names.

Obligation: changes to delimiter handling must not convert punctuation into
xrefs and must not change name xref behavior.

I5. Unsupported syntax fallback remains a frame condition.

Source: `_parse_annotation()` catches `SyntaxError` from unsupported AST shapes
and returns a single xref for the original annotation string.

Obligation: the fix must not broaden or narrow unsupported-syntax handling
except through the explicitly supported empty list/tuple delimiter cases.

I6. Public compatibility is preserved.

Source: `_parse_annotation()` is called by Python-domain argument and return
signature parsing; no public task asks for an API shape change.

Obligation: function signatures, return types, node classes, and call sites must
remain compatible.
