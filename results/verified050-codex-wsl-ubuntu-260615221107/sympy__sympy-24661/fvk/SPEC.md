# FVK Spec for sympy__sympy-24661

Status: constructed, not machine-checked. No tests, Python code, or K tools were
run.

## Scope

Targeted production code:

- `repo/sympy/parsing/sympy_parser.py`
  - `parse_expr`, only the `evaluate=False` path that calls `evaluateFalse`
  - `evaluateFalse`
  - `EvaluateFalseTransformer.visit_Compare`
- `repo/sympy/core/sympify.py`
  - string input delegation to `parse_expr`; no code change required

The proof scope is partial correctness of the transformation: if parsing reaches
the `evaluate=False` AST rewrite path and then evaluates the rewritten AST in a
namespace containing the SymPy relational constructors, supported Python
comparison syntax is represented by unevaluated SymPy relational constructors.

## Public Intent Ledger

I1. Source: prompt. Evidence: "`parse_expr('1 < 2', evaluate=False)` returns
`True`." Obligation: this is the legacy bug, not the desired behavior.
Status: encoded as a resolved finding and proof obligation.

I2. Source: prompt. Evidence: "The result that should be returned is:
`Lt(1, 2, evaluate=False)`." Obligation: for `<`, the `evaluate=False` parser
path must construct `Lt(left, right, evaluate=False)` rather than allowing
Python comparison evaluation. Status: encoded in PO1 and PO4.

I3. Source: prompt/public hint. Evidence: "`sympify` function calls
`parse_expr` if it is given a string." Obligation: fix the parser path; do not
add an independent `sympify` workaround. Status: encoded in PO5.

I4. Source: prompt/public hint. Evidence: "`parse_expr(evaluate=False)` works
by handling specific types of nodes when parsing, but it doesn't currently have
any support for inequalities." Obligation: repair the AST transformer, not the
relational constructors. Status: encoded in PO1 through PO4.

I5. Source: prompt/public discussion. Evidence: the proposed operator family
listed equality, inequality, strict/weak less-than, and strict/weak
greater-than, and the correction named `ast.Eq`. Obligation: cover the standard
Python comparison operator family represented by `ast.Compare`: `==`, `!=`,
`<`, `<=`, `>`, `>=`. Status: encoded in PO1 through PO3.

I6. Source: implementation. Evidence: `sympy/__init__.py` exports `Eq`, `Ne`,
`Lt`, `Le`, `Gt`, `Ge`, and `And`; `parse_expr` default globals execute
`from sympy import *`. Obligation: the rewritten AST names are available in the
default parser environment. Status: implementation fact used by PO4, not an
independent intent source.

## Intent-Only Contract

For any input expression whose transformed Python AST contains a comparison node
with every operator in `{ast.Eq, ast.NotEq, ast.Lt, ast.LtE, ast.Gt, ast.GtE}`,
and for `parse_expr(..., evaluate=False)`:

- The parser must recursively apply the existing evaluate-false transformation
  to the left operand and comparator operands.
- A single comparison must be rewritten to the corresponding SymPy relational
  constructor with `evaluate=False`:
  - `==` -> `Eq(left, right, evaluate=False)`
  - `!=` -> `Ne(left, right, evaluate=False)`
  - `<` -> `Lt(left, right, evaluate=False)`
  - `<=` -> `Le(left, right, evaluate=False)`
  - `>` -> `Gt(left, right, evaluate=False)`
  - `>=` -> `Ge(left, right, evaluate=False)`
- A chained comparison must be rewritten as `And` of the pairwise relational
  constructor calls, with `evaluate=False` on every relational and on `And`.
  This keeps the same comparison-node family from falling back to Python's
  boolean comparison-chain evaluation.
- Unsupported Python comparison operators such as `is`, `is not`, `in`, and
  `not in` are outside the public issue's relational-constructor family and
  must keep the transformer fallback behavior.

Frame conditions:

- `parse_expr(..., evaluate=True)` is unchanged.
- Existing evaluate-false rewrites for `BinOp` and whitelisted calls are
  unchanged.
- `sympify` remains a delegation path to `parse_expr`; no separate behavior or
  signature change is introduced.
- No test files are modified.

## Formal Spec English

FC1. A supported one-operator `ast.Compare` node is transformed to exactly one
SymPy relational `ast.Call`, where the function name is selected by the operator
mapping and the keyword list contains `evaluate=False`.

FC2. A supported chained `ast.Compare` node with operands `e0 op0 e1 op1 ... opN
eN+1` is transformed to `And(R0, ..., RN, evaluate=False)`, where each `Ri` is
the mapped relational call over recursively transformed adjacent operands.

FC3. `parse_expr` with `evaluate=False` compiles and evaluates the AST returned
by `evaluateFalse`; therefore, for the issue input `1 < 2`, the evaluated object
is produced by `Lt(Integer(1), Integer(2), evaluate=False)` rather than Python
comparison evaluation.

FC4. For string input, `sympify(..., evaluate=False)` passes `evaluate=False` to
`parse_expr`, so the same comparison rewrite applies.

FC5. The repair does not alter public function signatures, public class
signatures, or the `evaluate=True` path.

## Adequacy Audit

- FC1 matches I2, I4, and I5: pass.
- FC2 is a family-completeness extension of I4/I5 over the same `ast.Compare`
  node type: pass, with the noted mathematical-expression assumption in
  `FINDINGS.md` F4.
- FC3 matches I1 and I2: pass.
- FC4 matches I3: pass.
- FC5 matches the task's minimal-source-change requirement and the public API
  compatibility audit: pass.

## Public Compatibility Audit

- Changed symbol: internal class `EvaluateFalseTransformer`.
- Changed method: `visit_Compare`, newly added override of `ast.NodeTransformer`
  dispatch.
- Public signatures changed: none.
- Public callsites requiring updates: none found in the audited source path;
  callers already invoke `parse_expr`/`sympify` with the existing `evaluate`
  parameter.
- Subclass/override compatibility: no public subclass or override of
  `EvaluateFalseTransformer` was identified in the audited source. The added
  method follows the standard `ast.NodeTransformer.visit_Compare` dispatch
  shape.

