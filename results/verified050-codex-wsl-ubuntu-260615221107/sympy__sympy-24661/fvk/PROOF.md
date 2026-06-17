# FVK Constructed Proof for sympy__sympy-24661

Status: constructed, not machine-checked. No tests, Python code, or K tools were
run.

## Claims Proved in This Construction

The constructed proof covers the obligations in `fvk/PROOF_OBLIGATIONS.md`:

- PO1: supported single comparisons become unevaluated SymPy relational calls.
- PO2: supported chained comparisons become an unevaluated `And` of pairwise
  unevaluated SymPy relational calls.
- PO3: unsupported comparison operators delegate to `generic_visit`.
- PO4: `parse_expr(..., evaluate=False)` compiles and evaluates the rewritten
  AST.
- PO5: `sympify(..., evaluate=False)` on strings delegates to `parse_expr`.
- PO6: the fix keeps public signatures and unrelated parser behavior unchanged.
- PO7: all proof and test-removal claims remain conditioned on future execution.

## Proof Sketch

### PO1: Single Comparison

For a node `Compare(left=L, ops=[op], comparators=[R])` with `op.__class__` in
`relational_operators`, the `all(...)` guard in `visit_Compare` is true. The
method computes `left = self.visit(node.left)`, so `left = V(L)`. It enters the
loop once, maps `op.__class__` through `relational_operators`, computes
`right = self.visit(comparator)`, so `right = V(R)`, and appends:

```text
ast.Call(func=ast.Name(id=Rel(op.__class__), ctx=ast.Load()),
         args=[V(L), V(R)],
         keywords=[evaluate=False])
```

After the loop, `len(relations) == 1`, so the method returns that relational
call directly. For the issue operator `ast.Lt`, `Rel(ast.Lt) = "Lt"`, giving
`Lt(V(1), V(2), evaluate=False)`.

### PO2: Chained Comparisons

For a supported chain, `all(...)` is true. The loop invariant is:

```text
After k loop iterations:
  relations == [
    EvalFalseCall(Rel(op0), [V(E0), V(E1)]),
    ...,
    EvalFalseCall(Rel(op(k-1)), [V(E(k-1)), V(Ek)])
  ]
  left == V(Ek)
```

Initialization holds before the loop with `relations == []` and `left == V(E0)`.
One loop iteration appends the mapped relational for the current adjacent pair
and updates `left` to the current `right`, establishing the invariant for
`k + 1`. On loop exit, the invariant covers every adjacent pair. If there is one
relation, PO1's result is returned. If there are multiple relations, the method
returns `And(relations..., evaluate=False)`, so Python's comparison-chain truth
evaluation is not used on the evaluate-false path.

### PO3: Unsupported Operators

If any operator class in `node.ops` is not in `relational_operators`, the
`all(...)` guard is false. The method returns `self.generic_visit(node)`. This
preserves the transformer's fallback behavior for Python-specific comparison
forms that are not part of the SymPy relational-constructor family named by the
issue.

### PO4: `parse_expr` Path

`parse_expr` computes transformed source text through `stringify_expr`. When
`evaluate` is false, it compiles `evaluateFalse(code)`. `evaluateFalse` parses
the source text into an AST, applies `EvaluateFalseTransformer`, wraps the first
expression body in `ast.Expression`, and fixes locations. Therefore, for source
text whose AST contains a supported comparison, PO1 or PO2 supplies the AST that
`parse_expr` compiles. The default `global_dict` imports `Eq`, `Ne`, `Lt`, `Le`,
`Gt`, `Ge`, and `And` from SymPy, so the generated call names resolve.

For `parse_expr('1 < 2', evaluate=False)`, the comparison operator is `ast.Lt`,
so the compiled expression contains `Lt(Integer(1), Integer(2),
evaluate=False)`. The relational constructor documentation and implementation
show that `evaluate=False` returns an unevaluated relational rather than the
boolean `True`.

### PO5: `sympify` Delegation

For string input, `sympify` imports `parse_expr`, builds the usual string
transformations, and calls `parse_expr(..., evaluate=evaluate)`. Therefore
`sympify('1 < 2', evaluate=False)` reaches the same `parse_expr` proof path as
PO4 and receives the same unevaluated relational result.

### PO6: Frame

The diff adds a new comparison map and a `visit_Compare` override. It does not
change public signatures, the `evaluate=True` branch in `parse_expr`, existing
`visit_BinOp` code, or `sympify`. It also does not edit tests. The only changed
behavior is for `evaluate=False` AST comparison nodes handled by the new method.

## Adequacy Gate

The English claims in `fvk/SPEC.md` are no weaker than the public intent:

- The prompt's required `Lt(1, 2, evaluate=False)` result is covered by PO1 and
  PO4.
- The prompt's `sympify` example is covered by PO5.
- The hinted comparison operator family is covered by PO1 through PO3.

The claims are not stronger in a way that justifies extra source edits: explicit
relational constructor calls are documented as a non-blocking scope decision in
F5, because the public bug and hint identify comparison syntax and AST
comparison operators.

## Commands Not Run

The FVK documents call for K commands, but this benchmark forbids running them.
Supporting constructed K skeletons are included as `fvk/mini-sympy-parser.k`
and `fvk/sympy-parser-spec.k`. The commands for a full machine-checking pass
would be:

```sh
kompile fvk/mini-sympy-parser.k --backend haskell
kast --backend haskell fvk/sympy-parser-spec.k
kprove fvk/sympy-parser-spec.k
```

Expected result after completing/running the executable mini-semantics: `#Top`
for the comparison rewrite claims. In this workspace, these commands are
documentation only and were not executed.

## Test Recommendation

No tests were run or removed. Suggested tests to add or keep in a normal
development environment:

- `parse_expr('1 < 2', evaluate=False)` equals `Lt(1, 2, evaluate=False)`.
- The same shape for `<=`, `>`, `>=`, `==`, and `!=`.
- A nested arithmetic operand case, for example a comparison whose side contains
  an unevaluated `Add` from the existing transformer.
- `sympify('1 < 2', evaluate=False)` follows the parser result.
- A chained comparison produces an unevaluated `And` of pairwise relationals.

Any future test-removal recommendation is conditioned on actual machine
checking and normal project test execution.
