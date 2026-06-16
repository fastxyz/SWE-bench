# FVK Constructed Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Claim Summary

For every supported Python signature AST parsed by `signature_from_str()`:

1. If a parameter default is a tuple expression, `signature_from_ast()` stores a
   parenthesized tuple-expression string for that default.
2. The Python domain then inserts that stored default string into the
   `default_value` node, so the rendered signature preserves tuple parentheses.
3. Annotation and return-annotation rendering remain on the original unparse
   path and therefore preserve existing `Tuple[int, int]` behavior.

These claims discharge proof obligations O1 through O6 in
`fvk/PROOF_OBLIGATIONS.md`, subject to the honesty gate O7.

## Symbolic Failure Before V1

Input signature fragment:

```text
color=(1, 1, 1)
```

Source path:

1. `sphinx.domains.python._parse_arglist()` calls
   `signature_from_str("(lines, color=(1, 1, 1), width=5)")`.
2. `signature_from_str()` parses `def func(...): pass` into a Python AST.
3. The `color` default is an `ast.Tuple` with three element nodes.
4. Before V1, `signature_from_ast()` called the normal `ast_unparse()` for the
   default.
5. Normal `visit_Tuple()` for a non-empty tuple returns only the joined element
   list: `1, 1, 1`.
6. `_parse_arglist()` writes that string into the default value node.

Constructed result before V1:

```text
color=1, 1, 1
```

This violates intent ledger entries E1 and E2.

## Symbolic Execution After V1

Input signature fragment:

```text
color=(1, 1, 1)
```

Source path:

1. `signature_from_str()` still parses the signature into an AST and delegates
   to `signature_from_ast()`.
2. `signature_from_ast()` reaches the positional-or-keyword branch for `color`.
3. Because the parameter has a default, it calls `ast_unparse_default(default)`.
4. `unparse_default()` constructs `_UnparseVisitor(parenthesize_tuples=True)`.
5. `visit_Tuple()` renders the three elements with the same visitor and then,
   because `parenthesize_tuples` is true and there is more than one element,
   returns `(1, 1, 1)`.
6. `signature_from_ast()` stores `(1, 1, 1)` as `param.default`.
7. `_parse_arglist()` writes that stored string into the default value node.

Constructed result after V1:

```text
color=(1, 1, 1)
```

This satisfies O1 and O5.

## Case Split

### Empty Tuple

`visit_Tuple()` returns `()` independent of default context. Therefore an empty
tuple default remains `()`.

Obligations discharged:

- O1

### Singleton Tuple

In default context, a single tuple element is rendered and a trailing comma is
added before closing the parentheses. Therefore `(x,)` remains distinguishable
from `(x)`.

Obligations discharged:

- O1

### Multi-Element Tuple

In default context, tuple elements are joined with `, ` and wrapped in
parentheses. Therefore `(1, 1, 1)` is rendered as `(1, 1, 1)`.

Obligations discharged:

- O1

### Nested Tuple In Default Expressions

Default context is stored on the visitor instance. Existing child-expression
visitors call `self.visit(...)`, so nested tuple expressions inherit default
context unless a specific visitor deliberately changes context. Therefore
defaults such as `((1, 2), 3)` are not flattened into `(1, 2, 3)`.

Obligations discharged:

- O2

### Subscript Slices

`visit_Subscript()` delegates the slice to `_visit_subscript_slice()`. If the
top-level slice node is a tuple, `_visit_subscript_slice()` renders it as the
comma-separated slice list rather than invoking `visit_Tuple()` as a parenthesized
tuple expression. Therefore `Tuple[int, int]` remains `Tuple[int, int]`.

Because tuple children of that top-level slice are still rendered with
`self.visit(...)`, nested tuple values remain distinguishable in default context.

Obligations discharged:

- O4

### Annotations And Return Annotations

`signature_from_ast()` continues to call `ast_unparse()` for annotations and the
return annotation. These paths do not construct `_UnparseVisitor` with
`parenthesize_tuples=True`.

Obligations discharged:

- O3
- O5

## Constructed K Core

The side artifacts model the relevant rendering relation:

- `fvk/mini-signature-default.k`
- `fvk/signature-default-spec.k`

They abstract away full Python AST parsing and model only the property-bearing
axis: normal rendering versus default rendering of tuple and subscript nodes.
That abstraction distinguishes a failing instance (`color=1, 1, 1`) from the
passing instance (`color=(1, 1, 1)`), so it does not erase the defect.

## Commands Not Run

The exact commands to machine-check the constructed proof later would be:

```sh
kompile fvk/mini-signature-default.k --backend haskell
kast --backend haskell fvk/signature-default-spec.k
kprove fvk/signature-default-spec.k
```

Expected machine-check result, if the constructed artifacts are accepted by K:
`#Top`. This was not verified in this session.

## Test Guidance

No tests were edited. Because the proof is not machine-checked, no existing test
should be removed on the basis of this FVK run.

Recommended tests to add in a normal development environment:

- `signature_from_str("(color=(1, 1, 1))")` stores `"(1, 1, 1)"` as the default.
- the Python-domain rendered signature for `add_lines(lines, color=(1, 1, 1))`
  contains `color=(1, 1, 1)`.
- `signature_from_str("(x: Tuple[int, int])")` still stores the annotation
  `Tuple[int, int]`.
- singleton tuple defaults render as `(1,)`.

## Residual Risk

The proof is partial and local to the supported AST fragment used by
`signature_from_ast()` and the public issue. It does not claim full-fidelity
unparsing for every Python AST construct already unsupported by Sphinx's
cut-down unparser. It also does not prove termination, although the audited
functions are structurally recursive over finite AST nodes.

## Verdict

The constructed proof closes the obligations relevant to the public issue. No
source change beyond V1 is justified by the FVK findings.
