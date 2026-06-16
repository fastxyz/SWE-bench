# FVK Proof Obligations

Status: constructed from public intent and source inspection; not machine-checked.

## O1: Tuple Default Preservation

For any supported AST tuple node `T` used as a default-value expression:

- `T = ()` renders as `()`.
- `T = (x,)` renders as `(render_default(x),)`.
- `T = (x1, ..., xn)` for `n > 1` renders as
  `(render_default(x1), ..., render_default(xn))`.

Source mapping:

- `repo/sphinx/pycode/ast.py`: `unparse_default()`
- `repo/sphinx/pycode/ast.py`: `_UnparseVisitor.visit_Tuple()`

Intent evidence:

- `fvk/SPEC.md` E1, E2

## O2: Default Context Propagates Into Child Expressions

When `unparse_default()` renders a supported default expression, tuple
subexpressions outside the top-level subscript-slice exception keep the same
default-value context. Nested tuple defaults therefore remain tuple expressions
rather than flattened comma lists.

Source mapping:

- `repo/sphinx/pycode/ast.py`: `_UnparseVisitor(parenthesize_tuples=True)`
- child calls to `self.visit(...)` in the existing expression visitors

Intent evidence:

- `fvk/SPEC.md` E1, E2

## O3: Normal Tuple Unparse Is Unchanged

Calling the preexisting `unparse()` function must not parenthesize non-empty
top-level tuple AST nodes. This preserves existing callers that depend on the
normal AST unparse behavior.

Source mapping:

- `repo/sphinx/pycode/ast.py`: `unparse()` still constructs
  `_UnparseVisitor()` with the default context flag set to `False`.

Intent evidence:

- `fvk/SPEC.md` E5

## O4: Subscript Slice Tuple Frame Condition

When a tuple AST node is the top-level slice of a subscript expression, it is
rendered as a comma list inside brackets rather than as a parenthesized tuple.

Required consequence:

```text
Tuple[int, int]
```

must remain:

```text
Tuple[int, int]
```

and must not become:

```text
Tuple[(int, int)]
```

Source mapping:

- `repo/sphinx/pycode/ast.py`: `_visit_subscript_slice()`
- `repo/sphinx/pycode/ast.py`: `visit_Subscript()`

Intent evidence:

- `fvk/SPEC.md` E5

## O5: Signature Integration Covers Every Default Branch

`signature_from_ast()` must use default-value rendering for every parameter kind
that can legally have a default:

- positional-only
- positional-or-keyword
- keyword-only

It must not use default-value rendering for annotations or return annotations.

Source mapping:

- `repo/sphinx/util/inspect.py`: `signature_from_ast()`

Intent evidence:

- `fvk/SPEC.md` E3, E4, E6

## O6: Public Compatibility

The fix must not change public callable signatures, writer APIs, or existing
callers of `unparse()`.

Source mapping:

- `unparse_default()` is additive.
- `signature_from_ast()` changes only internal default-string construction.

Intent evidence:

- `fvk/SPEC.md` E5, E6

## O7: Honesty Gate

Because this session forbids running code, tests, or K tooling, all proof claims
remain constructed rather than machine-checked. The artifacts must record exact
commands but not imply that `kompile`, `kast`, or `kprove` returned `#Top`.

Source mapping:

- `fvk/PROOF.md`
- `fvk/mini-signature-default.k`
- `fvk/signature-default-spec.k`

Intent evidence:

- User task instructions
- FVK verify honesty gate

## Dependency Graph

```text
E1,E2 -> O1 -> F1 closed
E1,E2 -> O2 -> nested tuple cases covered
E5    -> O3 -> normal unparse compatibility
E5    -> O4 -> annotation/subscript compatibility
E3,E4,E6 -> O5 -> autodoc/Python-domain integration
E5,E6 -> O6 -> public compatibility
user/FVK no-exec rules -> O7 -> proof caveat
```
