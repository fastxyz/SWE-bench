# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, tests, Python, or project code were executed.

## Formal Core

- Semantics fragment: `fvk/mini-java-arithmetic.k`.
- Claims: `fvk/arithmetic-post-aggregator-spec.k`.
- Exact commands to machine-check later, not run in this benchmark:

```sh
cd fvk
kompile mini-java-arithmetic.k --backend haskell
kast --backend haskell arithmetic-post-aggregator-spec.k
kprove arithmetic-post-aggregator-spec.k
```

Expected machine-check result after installing/configuring K: `#Top` for all claims.

## Proof Sketch

### PO-1 / LOOKUP-POW

The V1 enum contains `POW("pow")`. The existing static initializer iterates over `Ops.values()` and inserts `LOOKUP_MAP.put(op.getFn(), op)`. Instantiating the loop body at `op = POW` gives `LOOKUP_MAP["pow"] = POW`. Therefore constructor lookup for `fnName = "pow"` no longer reaches the `op == null` error branch.

### PO-2 / POW-PAIR

The V1 `POW` enum override is:

```java
return Math.pow(lhs, rhs);
```

The mini-K rule `opCompute(POW, A, B) => mathPow(A, B)` is the direct semantic abstraction of that Java statement. Since `mathPow` denotes Java `Math.pow`, the claim matches the public intent "equivalent to Math.pow()".

### PO-3 / POW-FOLD-TWO and POW-FOLD-THREE

The Java compute method initializes `retVal` from the first field's numeric double value. Each subsequent non-null field executes one loop iteration and updates `retVal` with `op.compute(retVal, nextVal.doubleValue())`.

For two fields `[A, B]`, symbolic execution reaches one loop iteration and returns `opCompute(POW, A, B)`, which rewrites to `mathPow(A, B)`.

For three fields `[A, B, C]`, symbolic execution performs the first iteration to get `mathPow(A, B)`, then a second iteration to get `mathPow(mathPow(A, B), C)`. This is exactly the public left-to-right arithmetic post-aggregator contract.

### PO-4 / POW-NULL

Both Java null checks return immediately before any pairwise operation. In the mini-K model, `compute(OP, cons(null, XS)) => null` and `computeTail(OP, ACC, cons(null, XS)) => null`. This proves that `pow` inherits the existing arithmetic post-aggregator null propagation.

### PO-5 / POW-CACHE-ORDER

The cache-key branch calls `appendCacheables(fields)` when `preserveFieldOrderInCacheKey(op)` is true and `appendCacheablesIgnoringOrder(fields)` otherwise. V1 adds `POW` to the true-returning switch arm. Since `pow(A,B)` is not generally equal to `pow(B,A)`, this discharges the order-sensitive cache obligation.

### PO-6 / Frame

The diff adds one enum constant and one switch label. It does not alter the existing compute bodies or cache-key classification for `+`, `-`, `*`, `/`, or `quotient`, and it does not change constructor signatures or JSON property names. Existing public behavior for other operations is therefore framed unchanged.

## Adequacy and Completeness Check

The claims cover the full issue intent: recognition of `pow`, `Math.pow` pair semantics, square/cube/square-root operands through numeric exponents, left-to-right folding under the existing arithmetic post-aggregator contract, null propagation, and cache-key correctness. The claims intentionally do not cover a `power` alias because public evidence supports `pow` as the function name.

## Test Guidance

No tests were edited. No test removal is recommended because the proof is constructed, not machine-checked, and this benchmark has a fixed test suite. Useful tests for a normal development workflow would include:

- constructing an arithmetic post-aggregator with `fn = "pow"` and constants `2` and `3`;
- square, cube, and square-root exponent examples;
- null propagation through a `pow` post-aggregator;
- cache-key inequality for swapped `pow` fields.

## Residual Risk

- The K proof abstracts Java double values and `Math.pow`; it proves dispatch to the JDK primitive, not the internals of the JDK implementation.
- The proof is partial correctness and constructed only. It must be machine-checked with the emitted commands before claiming K-verified status.
- Documentation updates are product work outside this source-code benchmark patch.
