# FVK SPEC

Status: constructed from public/local evidence, not machine-checked.

## Scope

Target under audit: `sphinx.pycode.ast.unparse()` as implemented by
`_UnparseVisitor`, specifically tuple-valued AST nodes and the subscript path
that formats tuple slices. The observable is the returned string.

The audit covers:

- direct `ast.Tuple` rendering through `visit_Tuple()`;
- `ast.Tuple` rendering when a tuple is the simple slice in `visit_Subscript()`;
- frame behavior for empty tuples, multi-element tuples, and non-tuple nodes.

The local helper `sphinx.domains.python._parse_annotation().unparse()` is a
separate docutils-node renderer, not the string-returning `sphinx.pycode.ast`
API named by the issue. It is included in the compatibility audit as an
unchanged separate surface, not as the repair target.

## Intent Spec

I-001: A one-element Python tuple must be rendered with the trailing comma that
distinguishes tuple syntax from a parenthesized expression.

I-002: The concrete issue example requires `unparse(parse("(1,)").body[0].value)`
to return `(1,)`, not `(1)`.

I-003: The existing public behavior for empty tuples and multi-element tuples is
preserved: `()` stays `()`, and `(1, 2, 3)` stays `(1, 2, 3)`.

I-004: If `pycode.ast.unparse()` formats a tuple through an alternate local
contributor, that contributor must preserve tuple cardinality as well. In
particular, a one-element tuple slice in a subscript must retain a comma, because
`obj[1,]` and `obj[1]` are different AST shapes.

I-005: No public API signature, return type, or test file should be changed.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | prompt | "1-element tuple rendered incorrectly" | Cardinality-one tuple is the boundary case. | Encoded by PO-1 and PO-3. |
| E-002 | prompt | "`(1,)` is rendered as `(1)`, but should keep the trailing comma." | Direct one-element tuple output must include the comma. | Encoded by PO-1. |
| E-003 | prompt | Suggested testcase `("(1,)", "(1,)")` | The exact direct expression example is in domain. | Encoded by PO-1. |
| E-004 | public tests | Existing `test_pycode_ast.py` cases for `(1, 2, 3)`, `()`, and `Tuple[int, int]` | Preserve non-buggy tuple and subscript tuple-list formatting. | Encoded by PO-2 and PO-4. |
| E-005 | implementation | `visit_Subscript()` manually joins simple tuple slice elements instead of calling `visit_Tuple()`. | Sibling formatter must be audited for the same one-element cardinality defect. | Finding F-002; fixed in V2. |
| E-006 | implementation/callsites | `unparse()` call sites consume strings; V2 changes no function signature. | Compatibility frame: callers keep the same API. | Encoded by PO-5. |

## Formal Spec English

FS-001: For any rendered child expression `x`, rendering `Tuple([x])` returns
`("(" + render(x) + ",)")`.

FS-002: Rendering `Tuple([])` returns `"()"`.

FS-003: Rendering `Tuple([x1, x2, ...])` for two or more elements returns the
same parenthesized comma-and-space joined form as before.

FS-004: Rendering `Subscript(value, Tuple([x]))` returns
`render(value) + "[" + render(x) + ",]"`.

FS-005: Rendering `Subscript(value, Tuple([x1, x2, ...]))` for two or more
simple slice elements returns the same bracketed comma-and-space joined form as
before, without tuple parentheses.

FS-006: Empty tuple slices, starred tuple slices, non-tuple slices, and all
non-tuple expression visitors continue through their existing branches.

## Adequacy Audit

| Formal item | Intent item | Verdict | Reason |
| --- | --- | --- | --- |
| FS-001 | I-001, I-002 | Pass | It states the exact missing comma for direct one-element tuples. |
| FS-002 | I-003 | Pass | It preserves the existing empty tuple behavior. |
| FS-003 | I-003 | Pass | It preserves existing multi-element tuple behavior. |
| FS-004 | I-001, I-004 | Pass | It applies the same cardinality-marker obligation to the sibling tuple-slice formatter. |
| FS-005 | I-003 | Pass | It preserves the existing `Tuple[int, int]`-style simple subscript tuple-list behavior. |
| FS-006 | I-005 | Pass | It frames behavior not implicated by the one-element tuple bug. |

No formal-English item is candidate-derived without public or code-local
provenance. The subscript obligation is not copied from V2; it comes from the
prompt's cardinality requirement plus the implementation evidence that subscript
tuple slices bypass `visit_Tuple()`.

## Public Compatibility Audit

Changed symbol: `_UnparseVisitor.visit_Tuple(self, node: ast.Tuple) -> str`.

- Signature unchanged.
- Return type unchanged.
- Existing empty tuple and multi-element tuple branches are preserved.
- Public call sites use `unparse()` and continue receiving strings.

Changed symbol: `_UnparseVisitor.visit_Subscript(self, node: ast.Subscript) -> str`.

- Signature unchanged.
- Return type unchanged.
- Multi-element simple tuple slices keep the existing flattened bracket form,
  preserving `Tuple[int, int]`.
- The only intentional output change is the one-element simple tuple slice,
  where the previous output erased tuple cardinality.

Tests were not modified.

## Formal Core

The constructed mini semantics is in `fvk/mini-pycode-unparse.k`.
The constructed claims are in `fvk/pycode-ast-tuple-spec.k`.

Expected machine-check commands, not executed in this session:

```sh
cd fvk
kompile mini-pycode-unparse.k --backend haskell
kast --backend haskell pycode-ast-tuple-spec.k
kprove pycode-ast-tuple-spec.k
```

Expected result if the mini semantics and claims are accepted by the K toolchain:
`#Top`.
