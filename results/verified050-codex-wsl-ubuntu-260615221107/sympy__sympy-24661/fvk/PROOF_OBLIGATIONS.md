# FVK Proof Obligations for sympy__sympy-24661

Status: constructed, not machine-checked.

## Notation

- `V(e)` means the result of recursively applying
  `EvaluateFalseTransformer.visit` to AST expression `e`.
- `Rel(op)` is the mapping:
  - `ast.Eq -> Eq`
  - `ast.NotEq -> Ne`
  - `ast.Lt -> Lt`
  - `ast.LtE -> Le`
  - `ast.Gt -> Gt`
  - `ast.GtE -> Ge`
- `EvalFalseCall(name, args)` means an `ast.Call` whose `func` is
  `ast.Name(id=name, ctx=ast.Load())`, whose positional arguments are `args`,
  and whose keyword list contains `evaluate=False`.

## PO1 - Single Supported Comparison Rewrite

For any `ast.Compare` node:

```text
Compare(left=L, ops=[op], comparators=[R])
```

where `op.__class__` is in `relational_operators`, `visit_Compare` must return:

```text
EvalFalseCall(Rel(op.__class__), [V(L), V(R)])
```

This discharges the direct issue example for `ast.Lt`.

Findings: F1, F3.

## PO2 - Chained Supported Comparison Rewrite

For any `ast.Compare` node:

```text
Compare(left=E0, ops=[op0, ..., opN], comparators=[E1, ..., E(N+1)])
```

where every `opI.__class__` is in `relational_operators`, `visit_Compare` must
construct the list:

```text
[
  EvalFalseCall(Rel(op0.__class__), [V(E0), V(E1)]),
  ...,
  EvalFalseCall(Rel(opN.__class__), [V(EN), V(E(N+1))])
]
```

If the list has one element, the method returns that element. If it has more
than one element, the method returns:

```text
EvalFalseCall("And", relations)
```

Loop invariant for the implementation loop over `zip(node.ops,
node.comparators)`: after `k` iterations, `relations` contains exactly the
mapped relational calls for the first `k` adjacent operand pairs, and `left`
holds `V(Ek)`.

Findings: F3, F4.

## PO3 - Unsupported Comparison Operators Preserve Fallback Behavior

For any `ast.Compare` node with at least one operator class outside
`relational_operators`, `visit_Compare` must delegate to `generic_visit(node)`.

This preserves fallback behavior for Python-specific comparisons such as `is`
and `in`, which the public issue did not identify as SymPy relational
constructors.

Findings: F3.

## PO4 - Parser Evaluation Path Uses the Rewritten AST

For `parse_expr(s, evaluate=False)`, after token transformations:

1. `parse_expr` calls `evaluateFalse(code)`.
2. `evaluateFalse` parses `code` into a Python AST.
3. `EvaluateFalseTransformer.visit` rewrites supported comparison nodes per
   PO1 or PO2.
4. `parse_expr` compiles and evaluates the transformed AST.
5. In the default parser globals, `Eq`, `Ne`, `Lt`, `Le`, `Gt`, `Ge`, and `And`
   are available through `from sympy import *`.

Therefore, the issue input `1 < 2` with `evaluate=False` reaches
`Lt(Integer(1), Integer(2), evaluate=False)` rather than Python comparison
truth evaluation.

Findings: F1.

## PO5 - `sympify` String Delegation

For string input `a`, `sympify(a, evaluate=False)` must call:

```text
parse_expr(a, ..., evaluate=False)
```

Therefore, the parser obligations PO1 through PO4 also discharge the public
`sympify('1 < 2', evaluate=False)` example.

Findings: F2.

## PO6 - Minimality and Compatibility Frame

The fix must not:

- change public function signatures;
- change `evaluate=True` behavior;
- change existing `visit_BinOp` behavior;
- add new name-based `visit_Call` rewrites unless public intent requires them;
- modify test files.

Findings: F5.

## PO7 - Honesty Gate and Deferred Execution

The proof must remain labeled constructed, not machine-checked. No tests,
imports, `kompile`, `kast`, or `kprove` commands may be run in this benchmark
workspace.

Findings: F6.

