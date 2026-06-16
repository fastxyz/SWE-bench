# Constructed Proof

Status: constructed, not machine-checked.

## Machine-Check Commands Not Executed

The benchmark instructions forbid running K tooling. These are the commands a later environment would run:

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell lambdify-recursive-to-string-spec.k
kprove lambdify-recursive-to-string-spec.k
```

Expected machine-check result, if the fragment and claims are accepted: `#Top` for all claims.

## Semantics Summary

`mini-python.k` models the relevant fragment as pure rendering over expression trees. `render` represents `_recursive_to_string`; `returnLine` represents `_EvaluatorPrinter.doprint` placing that rendered expression after `return `.

The proof is partial correctness over finite, acyclic `Node` values.

## Proof of `TUPLE-SINGLETON`

Start configuration:

```k
<k> render(pyTuple(cons(E, emptyNodes()))) </k>
```

The `pyTuple(cons(N, emptyNodes()))` rule in `mini-python.k` matches with substitution `N := E` and rewrites in one semantic step to:

```k
<k> "(" +String render(E) +String ",)" </k>
```

This is exactly the claim postcondition. The recursive call `render(E)` is framed as the element's own rendering obligation, so nested tuples receive the same rule at their level.

Code correspondence: V1's `if len(arg) == 1` branch returns `'({},)'.format(_recursive_to_string(doprint, arg[0]))`.

## Proof of `RETURN-SINGLETON-TUPLE`

Start configuration:

```k
<k> returnLine(pyTuple(cons(E, emptyNodes()))) </k>
```

The `returnLine` rule rewrites this to:

```k
<k> "return " +String render(pyTuple(cons(E, emptyNodes()))) </k>
```

By transitivity and the proved `TUPLE-SINGLETON` step, this reaches:

```k
<k> "return " +String "(" +String render(E) +String ",)" </k>
```

This proves that the corrected expression fragment propagates into the generated return line.

Code correspondence: `_EvaluatorPrinter.doprint` appends `return {str_expr}` after computing `str_expr` through `_recursive_to_string`.

## Proof of Frame Claims

`TUPLE-EMPTY` follows by direct application of the `render(pyTuple(emptyNodes())) => "()"` rule.

`TUPLE-MULTI` follows by direct application of the two-or-more tuple rule:

```k
render(pyTuple(cons(E1, cons(E2, REST))))
  => "(" +String renderNodes(cons(E1, cons(E2, REST))) +String ")"
```

`LIST-FRAME` follows by direct application of the list rule:

```k
render(pyList(NS)) => "[" +String renderNodes(NS) +String "]"
```

`LEAF-DELEGATION` follows by direct application of the leaf rules, e.g. `render(atom(S)) => S`.

Code correspondence: V1 does not change the empty tuple, multi-element tuple, list, raw-string, or scalar fallback branches.

## Adequacy and Compatibility

`SPEC_AUDIT.md` confirms that each claim maps back to `INTENT_SPEC.md` and the public evidence ledger. `PUBLIC_COMPATIBILITY_AUDIT.md` confirms that V1 changes no callable signature or dispatch protocol.

## Test Guidance

No test file was edited. If tests were allowed, useful tests would cover:

- `inspect.getsource(lambdify([], tuple([1])))` contains `return (1,)`;
- `inspect.getsource(lambdify([], tuple([1, 2])))` still contains `return (1, 2)`;
- a nested singleton tuple keeps the inner and outer commas where Python syntax requires them.

Those tests should not be removed based on this proof unless `kprove` is actually run and returns `#Top`.

