# Intent Specification

Status: constructed for audit, not machine-checked.

## Scope

The audited unit is `sympy.utilities.lambdify._recursive_to_string` as used by `_EvaluatorPrinter.doprint` to build the generated `return ...` line for `lambdify`. The in-scope inputs are finite, acyclic expression trees made from native Python `list` and `tuple` containers whose leaves are either SymPy/matrix objects printable by the selected `doprint`, raw strings accepted by `lambdify`, or scalar objects printable by `doprint`.

Unsupported arbitrary iterables remain outside this issue's intended domain because `_recursive_to_string` already rejects them with `NotImplementedError`; the public issue names native Python tuple behavior, not arbitrary iterables.

## Required Behavior

I1. A native Python tuple with exactly one element must be rendered as a Python singleton tuple literal with a trailing comma: `(<element>,)`.

I2. When that tuple expression is passed to `lambdify`, the generated source line must be `return (<element>,)`, so the function returns a tuple rather than the element.

I3. Native Python tuples with two or more elements must keep their existing valid tuple source form, order, and element rendering, e.g. `(1, 2)`.

I4. The empty tuple must continue to render as `()`.

I5. Native Python lists must continue to render as list literals with preserved order and recursive element rendering.

I6. SymPy `Tuple` objects must continue to use the printer path that already emits singleton tuple syntax correctly.

I7. The fix must not change the public API or accepted arguments of `lambdify`, `_EvaluatorPrinter.doprint`, or `_recursive_to_string`.

## Default-Domain Assumptions

D1. Python tuple syntax requires a trailing comma to distinguish a one-element tuple from parenthesized expression grouping.

D2. The formal proof is partial correctness over finite, acyclic container structures. Termination for cyclic containers is not proven and is not part of the public issue.

