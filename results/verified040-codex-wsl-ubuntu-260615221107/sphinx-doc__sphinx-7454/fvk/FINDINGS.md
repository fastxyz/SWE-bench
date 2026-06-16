# FVK Findings for sphinx-doc__sphinx-7454

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Findings

F-001, code bug, resolved by V1.
Input: signature-mode direct annotation text `None`.
Pre-V1 observed behavior: `_parse_annotation()` created
`pending_xref(refdomain="py", reftype="class", reftarget="None")`. In the
issue's intersphinx setup, the class role does not resolve to the Python docs
entry for the `None` singleton, and the later built-in fallback can leave plain
text.
Expected behavior: the pending reference should use the Python object role so
intersphinx can resolve Python's `None` singleton entry.
V1 status: resolved by `reftype = "obj" if text == "None" else "class"` in
`repo/sphinx/domains/python.py`.

F-002, consistency finding, resolved by V1.
Input: description-mode return type field with annotation `None` and
signature-mode return annotation `-> None`.
Observed before V1: description-mode field code already mapped `None` from the
class role to the object role, but signature-mode `_parse_annotation()` did not.
Expected behavior: both modes should use the same object-role reference for the
same `None` type hint.
V1 status: resolved by applying the same exact-target role distinction in the
signature parser.

F-003, frame condition, confirmed.
Input: signature-mode annotation text `int`, and any annotation token
`T != "None"`.
Observed in V1: the conditional falls through to `reftype="class"`.
Expected behavior: non-`None` type annotations retain existing class-role
cross-reference behavior.
V1 status: confirmed by proof obligations PO-003 and PO-004.

F-004, fallback-path coverage, confirmed.
Input: a direct annotation string `None` that enters `_parse_annotation()`'s
`except SyntaxError` fallback path, such as when the AST shape is unsupported.
Observed in V1: the fallback returns `[make_xref(annotation)]`, so exact text
`None` still receives `reftype="obj"`.
Expected behavior: direct `None` should not depend on which parser branch
recognized it.
V1 status: confirmed by proof obligation PO-005.

F-005, public compatibility, confirmed.
Input: all public consumers of Python-domain signature annotation nodes.
Observed in V1: the function signature and return shape of `_parse_annotation()`
are unchanged; only the internal `reftype` field for exact target `None`
changes.
Expected behavior: no public directive, config, event, or subclass API changes.
V1 status: confirmed by proof obligation PO-007.

F-006, proof limitation, open but non-code-blocking.
Input: the constructed FVK claims.
Observed: claims and proof were constructed but not machine-checked because the
task forbids running K tooling, tests, or Python.
Expected next step outside this constrained session: run the recorded
`kompile`, `kast`, and `kprove` commands, or keep all tests until such a check
returns `#Top`.
V1 status: no source change justified; this is an honesty-gate limitation, not
a discovered code bug.

## Proof-derived Findings from /verify

PF-001, no additional code bug.
The proof obligations cover the full issue intent slice: direct signature-mode
`None`, description/signature parity, and preservation of non-`None` signature
annotation behavior. No proof step required an implementation-derived side
condition that conflicts with public intent.

PF-002, test guidance only.
After machine checking, a unit test that directly asserts
`_parse_annotation("None")[0]["reftype"] == "obj"` would be subsumed by C-001.
Integration tests involving autodoc, intersphinx inventories, and HTML output
should be kept because this constructed proof models only the relevant role
selection and resolver ordering.
