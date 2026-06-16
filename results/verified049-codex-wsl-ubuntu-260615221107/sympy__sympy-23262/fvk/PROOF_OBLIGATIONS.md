# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Intent Adequacy

Every formal claim must trace to public intent or a named frame/default-domain condition, not to V1 behavior alone.

Discharge: `SPEC_AUDIT.md` marks all claims as pass. Singleton tuple claims trace to E1-E3 and D1; frame claims trace to E4/E6.

## PO-2: Singleton Tuple Source

For all in-scope elements `E`, `_recursive_to_string(doprint, (E,))` must produce `(<render(E)>,)`.

Formal claim: `TUPLE-SINGLETON`.

V1 discharge: the native tuple branch checks `len(arg) == 1` and returns `'({},)'.format(_recursive_to_string(doprint, arg[0]))`.

## PO-3: Existing Container Frame Conditions

The fix must preserve:

- empty tuple rendering as `()`;
- multi-element tuple rendering as parenthesized comma-space joined elements;
- list rendering as bracketed comma-space joined elements;
- recursive element rendering.

Formal claims: `TUPLE-EMPTY`, `TUPLE-MULTI`, `LIST-FRAME`, `LEAF-DELEGATION`.

V1 discharge: all non-singleton tuple/list branches continue through the pre-existing `left + ', '.join(...) + right` code path, and leaves are unchanged.

## PO-4: Nested Singleton Tuples

The singleton tuple rule must be recursive, so a singleton tuple nested inside another container keeps the comma at its own level.

Formal basis: `render` is recursively defined over `Node`; `TUPLE-SINGLETON` applies to every `E:Node`, including `pyTuple(...)`.

V1 discharge: the singleton branch calls `_recursive_to_string` on `arg[0]`, so nested containers are formatted before the outer comma is added.

## PO-5: Propagation to Generated Function Source

The corrected tuple expression string must become the actual generated return statement.

Formal claim: `RETURN-SINGLETON-TUPLE`.

V1 discharge: `_EvaluatorPrinter.doprint` assigns `str_expr = _recursive_to_string(self._exprrepr, expr)` and appends `return {str_expr}`. No intermediate code removes the comma.

## PO-6: Compatibility

The fix must not alter signatures, accepted input categories, or printer dispatch protocols.

Discharge: `PUBLIC_COMPATIBILITY_AUDIT.md` records no public API, virtual dispatch, subclass override, or producer/consumer shape change.

## PO-7: Honesty Gate

Because no execution environment exists, no tests, Python snippets, or K tools may be run. The proof can only be recorded as constructed, not machine-checked.

Discharge: all artifacts state this caveat, and no tests or code were executed.

