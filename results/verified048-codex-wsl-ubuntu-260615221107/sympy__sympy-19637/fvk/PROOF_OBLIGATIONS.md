# FVK Proof Obligations

Status: constructed, not machine-checked. These obligations are the basis for
confirming V1.

## PO-1: Public Issue Input Enters the No-Placeholder Branch

For `s = "(2*x)/(x-1)"`:

- `s` is a string.
- `hasLParen(s)` is true.
- `quoted(s)` is false.
- `balancedParens(s)` is true.
- `hasHackSpace(hackRewrite(stripSpaces(s)))` is false.

Therefore this input must follow PO-2 and must not require a defined `kern`.

## PO-2: No-Placeholder Branch Does Not Read `kern`

For every string `s` satisfying:

- `hasLParen(s)`
- `not quoted(s)`
- `balancedParens(s)`
- `not hasHackSpace(hackRewrite(stripSpaces(s)))`

the postcondition is:

- `hit` remains `False`;
- `kern` need not be assigned;
- the cleanup branch guarded by `if not hit: return expr` returns before
  `Symbol(kern)` can be evaluated;
- the function delegates to `sympify(hackRewrite(stripSpaces(s)))`, subject to
  whatever result or exception `sympify` itself produces.

This obligation directly discharges F-001.

## PO-3: Placeholder Branch Defines `kern` Before Setting `hit`

For every string `s` satisfying:

- `hasLParen(s)`
- `not quoted(s)`
- `balancedParens(s)`
- `hasHackSpace(hackRewrite(stripSpaces(s)))`

the postcondition is:

- `kern` is assigned a fresh placeholder not occurring in the rewritten string;
- all marker spaces are replaced by that placeholder;
- `hit` becomes true only after the assignment to `kern`;
- any later cleanup read of `kern` is dominated by the assignment.

This obligation preserves the documented anti-distribution hack.

## PO-4: TypeError Fallback Clears `hit`

If the placeholder parse raises `TypeError`, then:

- `s` is restored to `olds`;
- `hit` is set to `False`;
- the next parse attempt uses the un-hacked string;
- if that parse returns, the cleanup path is skipped, so `kern` is not required
  after fallback.

This obligation is traced to the docstring fallback behavior.

## PO-5: Unmatched Parenthesis Behavior Is Framed

For a string with `hasLParen(s)`, `not quoted(s)`, and unbalanced parentheses,
`kernS` raises `SympifyError('unmatched left parenthesis')` before any placeholder
logic. V1 does not alter this branch.

## PO-6: Public Compatibility Frame

The fix must preserve:

- public function name `kernS`;
- one-argument call shape;
- imports and callers;
- return/exception protocol except for removing the erroneous
  `UnboundLocalError` on in-domain no-placeholder strings.

V1 satisfies this because it changes only the indentation of an internal
assignment.

## PO-7: Explicit Proof Boundaries

The proof does not discharge:

- full correctness of `sympify`;
- full algebraic equality of returned SymPy expressions;
- total termination of the random fresh-name loop.

These boundaries do not block the V1 fix because the issue concerns an internal
undefined-local failure before those behaviors determine the result.
