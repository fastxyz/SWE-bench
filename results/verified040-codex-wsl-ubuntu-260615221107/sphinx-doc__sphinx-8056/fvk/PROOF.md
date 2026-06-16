# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`, or `kprove` were run.

## Claims

- C1: `transformParam(true, commaList("x1", "x2"), .TypeMap)` reaches `result("x1, x2", .TypeMap)`.
- C2: the C1 result, when paired with an explicit type field keyed by `x1, x2`, reaches `rendered("x1, x2", "array_like, optional")`.
- C3: `transformParam(true, inlineTyped("str", "sender"), .TypeMap)` reaches `result("sender", type("sender", "str", .TypeMap))`.
- C4: non-typed `commaList("x1", "x2")` reaches `result("x1, x2", .TypeMap)`.

## Symbolic Proof Sketch

For C1, the input is in the typed-field path and has the abstract shape `commaList(A, B)`, corresponding to a first whitespace token ending in a comma. The V2 semantics rule for comma lists applies directly and rewrites the state to `result(A + ", " + B, M)`. Instantiating `A = "x1"`, `B = "x2"`, and `M = .TypeMap` yields `result("x1, x2", .TypeMap)`.

For C2, reduce the nested `transformParam(true, commaList("x1", "x2"), .TypeMap)` term using C1's rule. Then the explicit type-field rule inserts `type("x1, x2", "array_like, optional", .TypeMap)`. The render rule requires the rendered parameter name and type-map key to be equal; both are `x1, x2`, so it reaches `rendered("x1, x2", "array_like, optional")`.

For C3, the input has the documented inline shorthand shape `inlineTyped(T, N)`, where the first token does not end with a comma. The inline typed-field rule rewrites to `result(N, type(N, T, M))`; instantiating `T = "str"` and `N = "sender"` yields the claim result. This proves the V2 guard is narrow.

For C4, `typedesc.is_typed` is false, so the non-typed preservation rule applies and leaves the comma-separated argument text unchanged.

There are no loops or recursive functions in the modeled fragment, so no circularity obligations are required.

## Relation to Source

The source implementation of C1 is the V2 condition in `repo/sphinx/util/docfields.py`: the inline `fieldarg.split(None, 1)` rewrite now runs only when `not argtype.endswith(',')`. For `fieldarg = "x1, x2"`, `argtype = "x1,"`, so the rewrite is skipped and the original `fieldarg` survives to match the explicit type-field key.

The C3 compatibility path remains unchanged for public forms such as `:param str sender:` because `argtype = "str"` does not end with a comma.

## Machine-Check Commands For Later

```sh
kompile fvk/mini-docfields.k --backend haskell
kast --backend haskell fvk/docfield-transformer-spec.k
kprove fvk/docfield-transformer-spec.k
```

Expected outcome after a real K run: `kprove` returns `#Top` for the four claims.

## Tests

No tests were run and no test files were modified. Because the proof is constructed but not machine-checked, no tests should be removed on the basis of these artifacts. Recommended tests to add or keep are listed in `fvk/ITERATION_GUIDANCE.md`.
