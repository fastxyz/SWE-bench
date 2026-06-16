# FVK Specification: sphinx-doc__sphinx-8265

Status: constructed from public intent and source inspection; not machine-checked.

## Scope

This audit targets the V1 fix for tuple default values in Python signatures:

- `repo/sphinx/pycode/ast.py`
  - `unparse_default()`
  - `_UnparseVisitor.visit_Tuple()`
  - `_UnparseVisitor.visit_Subscript()` and `_visit_subscript_slice()`
- `repo/sphinx/util/inspect.py`
  - `signature_from_ast()`
  - indirectly, `signature_from_str()` and `sphinx.domains.python._parse_arglist()`

The observable under audit is the rendered Python-domain callable signature text
for default values, especially a default tuple such as `(1, 1, 1)`.

## Intent-Only Specification

1. A Python callable signature containing a tuple default must render that
   default as a tuple expression, preserving parentheses:
   `color=(1, 1, 1)` must not render as `color=1, 1, 1`.
2. The fix must apply through the normal autodoc path, where autodoc emits a
   Python-domain directive and the Python domain reparses the argument list.
3. The fix must not change Python annotation rendering, especially subscripted
   annotations such as `Tuple[int, int]`.
4. Existing supported non-tuple defaults should keep their prior formatting.
5. The public API shape should remain compatible: no existing public function
   signature or caller contract should be changed.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt issue | `def add_lines(..., color=(1, 1, 1), ...)` is rendered as `color=1, 1, 1` | A tuple default's parentheses are semantically significant in rendered signatures. | Encoded by O1, O2 |
| E2 | prompt issue | Expected rendering is `color=(1, 1, 1)` | The output form is explicit: preserve parentheses in the default value node. | Encoded by O1 |
| E3 | prompt issue | Extension is `sphinx.ext.autodoc` and output is HTML | The relevant path is autodoc signature formatting followed by Python-domain parsing and writer output. | Encoded by O5 |
| E4 | source: `repo/sphinx/domains/python.py` | `_parse_arglist()` calls `signature_from_str()` and then writes `param.default` into the default value node | Correctness must hold at `signature_from_str()` / `signature_from_ast()` default-string construction. | Encoded by O5 |
| E5 | source: `repo/sphinx/pycode/ast.py` and visible tests | Existing `unparse()` intentionally renders top-level non-empty tuples without parentheses and annotations rely on subscript slices like `Tuple[int, int]` | Do not globally change normal tuple unparsing; add a default-value context instead. | Encoded by O3, O4 |
| E6 | source: `repo/sphinx/util/inspect.py` | `signature_from_ast()` has separate default, annotation, and return-annotation conversion sites | Defaults may change; annotations and returns should stay on the existing `ast_unparse()` path. | Encoded by O5 |

## Formal Contract

Let `render_default(AST)` denote `unparse_default(AST)` and `render_normal(AST)`
denote the existing `unparse(AST)`.

O1. Tuple default preservation:

- For a non-empty tuple AST with element renderings `e1, ..., en`, where
  `n > 1`, `render_default(tuple(e1, ..., en)) = "(" + e1 + ", " + ... + en + ")"`.
- For a singleton tuple AST with element rendering `e1`,
  `render_default(tuple(e1)) = "(" + e1 + ",)"`.
- For an empty tuple AST, `render_default(tuple()) = "()"`.

O2. Default-context propagation:

- If a supported default expression contains a tuple subexpression outside a
  subscript-slice top level, that tuple subexpression is rendered with O1.
  This covers nested tuple defaults and tuple values inside supported list,
  set, dict, call, binary, boolean, lambda-default, and unary expressions.

O3. Normal unparse frame condition:

- `render_normal(tuple(e1, ..., en))` remains the preexisting comma-list form
  for non-empty top-level tuples.

O4. Subscript-slice frame condition:

- A top-level tuple AST used as a subscript slice renders as a comma-list inside
  brackets, not as a parenthesized tuple. Therefore `Tuple[int, int]` remains
  `Tuple[int, int]`, not `Tuple[(int, int)]`.
- Nested tuple expressions inside such a slice remain visible to default
  context and may be parenthesized.

O5. Integration into signature parsing:

- `signature_from_ast()` uses `render_default()` for positional-only,
  positional-or-keyword, and keyword-only defaults.
- `signature_from_ast()` continues to use `render_normal()` for parameter
  annotations and return annotations.
- `signature_from_str()` inherits the same behavior because it delegates to
  `signature_from_ast()`.

O6. Public compatibility:

- No public callable signature is changed.
- Existing callers of `unparse()` keep the original behavior.
- `unparse_default()` is additive and used internally for default values only.

## Formal Core

Constructed K side artifacts are included as:

- `fvk/mini-signature-default.k`
- `fvk/signature-default-spec.k`

The exact commands to machine-check later are recorded in `fvk/PROOF.md`.
They were not executed in this session.

## Adequacy Audit

The formal contract directly encodes the issue's expected output form for tuple
defaults (E1, E2) and the actual source path that produces the default string
(E4, E6). The only frame conditions are independently justified by existing
annotation behavior and visible source/test expectations (E5). No postcondition
is derived solely from V1 behavior.

Conclusion: the spec is adequate for deciding whether V1 fixes the public issue.
