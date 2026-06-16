# FVK Specification

Status: constructed, not machine-checked.

## Target

This audit targets the native-container serialization helper:

- `repo/sympy/utilities/lambdify.py:_recursive_to_string`
- its use in `_EvaluatorPrinter.doprint` when forming the generated `return ...` line

The public issue is about native Python tuple expressions passed to `lambdify`, specifically one-element tuples. SymPy `Tuple` objects are supporting evidence because they already print the expected singleton tuple syntax through the normal printer path.

## Public Intent Ledger

The standalone ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The core obligations are:

- E1/E2/E3: a native one-element Python tuple must render as `(<element>,)` and generate `return (<element>,)`.
- E4: native tuples with two or more elements must stay in the existing `(a, b, ...)` form.
- E5: SymPy `Tuple(1)` already demonstrates the intended singleton source shape.
- E6/E7: `_recursive_to_string` is the relevant serialization point and `_EvaluatorPrinter.doprint` propagates its output into the final `return` statement.

## Formal Abstraction

`fvk/mini-python.k` models the relevant Python fragment as a pure renderer over finite expression trees:

- `atom(S)`, `basic(S)`, `matrix(S)`, and `pyString(S)` model leaves whose rendered form is already supplied by `doprint` or by a raw string.
- `pyList(Nodes)` and `pyTuple(Nodes)` model native Python containers.
- `render(Node)` models `_recursive_to_string`.
- `returnLine(Node)` models `_EvaluatorPrinter.doprint` appending `return ` to the rendered expression.

This abstraction is property-complete for the defect because it preserves the observable source string, container cardinality, element order, and the singleton tuple comma. It distinguishes the failing string `(1)` from the intended string `(1,)`.

## Contracts

S1. For every in-scope element `E`, `render(pyTuple(cons(E, emptyNodes())))` returns `"(" + render(E) + ",)"`.

S2. For every in-scope element `E`, `returnLine(pyTuple(cons(E, emptyNodes())))` returns `"return (" + render(E) + ",)"`.

S3. `render(pyTuple(emptyNodes()))` returns `"()"`.

S4. For every tuple with at least two elements, `render` returns `"(" + renderNodes(elements) + ")"`, preserving element order and separator `", "`.

S5. For every native list, `render` returns `"[" + renderNodes(elements) + "]"`, preserving element order and separator `", "`.

S6. Leaves are delegated unchanged to their supplied printed form, matching the helper's `doprint(arg)` or raw-string branches.

## V1 Audit Result

V1 added:

```python
if len(arg) == 1:
    return '({},)'.format(_recursive_to_string(doprint, arg[0]))
```

inside the native tuple branch of `_recursive_to_string`.

That exactly discharges S1. Because `_EvaluatorPrinter.doprint` directly appends `return {str_expr}`, S1 also discharges S2. The existing shared `left + ', '.join(...) + right` path remains unchanged for lists, empty tuples, and multi-element tuples, discharging S3-S5 as frame conditions. S6 is unchanged.

No source change beyond V1 is justified by the FVK audit.

