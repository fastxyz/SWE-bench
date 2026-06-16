# Constructed Proof

Status: constructed, not machine-checked.

## Adequacy gate

`INTENT_SPEC.md` states that `Q`/`Exists` pairs must combine without
`TypeError` for both `&` and `|`, that empty `Q()` remains the identity operand,
and that non-conditional operands remain rejected. `FORMAL_SPEC_ENGLISH.md`
paraphrases each K claim in those terms. `SPEC_AUDIT.md` marks every claim as
passing against the intent ledger. `PUBLIC_COMPATIBILITY_AUDIT.md` finds no
signature, return-shape, override, or public caller incompatibility.

The proof therefore reasons about the intended behavior, not merely V1's
current output.

## Claims

The claims live in `q-combine-spec.k` and use the mini semantics in
`mini-python.k`.

1. `(COMBINE-NONCOND)` proves that non-conditional operands still produce the
   `TypeError` result.
2. `(COMBINE-EMPTY-SELF-COND-EXPR)` proves the issue's minimal construction:
   empty left-hand `Q()` plus conditional expression returns `Q(expr)`.
3. `(COMBINE-LOOKUP-SELF-COND-EXPR-AND)` proves non-empty `Q & conditional`
   returns a combined `AND` `Q`.
4. `(COMBINE-LOOKUP-SELF-COND-EXPR-OR)` proves non-empty `Q | conditional`
   returns a combined `OR` `Q`.
5. `(DECONSTRUCT-EXPR-Q)` proves that a single expression child deconstructs
   through positional args.
6. `(DECONSTRUCT-LOOKUP-Q)` proves the previous single lookup deconstruction
   shape remains kwargs.

There are no loops or recursive calls in the audited fragment, so there are no
loop circularities. The proof is straight-line symbolic execution plus case
analysis over the guard predicates `isConditional`, `isQ`, and `isEmptyQ`.

## Proof sketch by obligation

PO-2: For `combine(lookupQ, nonCond, AND)`, `isConditional(nonCond)` rewrites to
`false`, so the first `combine` rule applies and rewrites to
`typeError(nonCond)`. This models `query_utils.py` lines 42-44.

PO-3 and PO-4: For `combine(emptyQ, condExpr, AND)`, `isConditional(condExpr)`
rewrites to `true`, so the second `combine` rule applies. `wrap(condExpr)`
rewrites to `exprQ`, modeling `other = Q(other)` at lines 45-46.

PO-5: The proof state is then `combineQ(emptyQ, exprQ, AND)`. `isEmptyQ(exprQ)`
is false and `isEmptyQ(emptyQ)` is true, so the empty-left rule rewrites to
`ok(clone(exprQ))`. `clone(exprQ)` rewrites through
`reconstruct(deconstructQ(exprQ))`; `deconstructQ(exprQ)` rewrites to
`argsExpr`, and `reconstruct(argsExpr)` rewrites to `exprQ`. The final result is
`ok(exprQ)`. This models `query_utils.py` lines 53-55 plus the expression-child
branch at lines 90-95.

PO-6: For `combine(lookupQ, condExpr, AND)`, the same conditional and wrapping
steps produce `combineQ(lookupQ, exprQ, AND)`, which rewrites to
`ok(andLookupExprQ)`. The `OR` case rewrites analogously to
`ok(orLookupExprQ)`. This models the non-empty construction path at
`query_utils.py` lines 57-61.

PO-7: `deconstructQ(exprQ)` rewrites to `argsExpr`, while
`deconstructQ(lookupQ)` rewrites to `kwargsLookup`. These claims model the
branch split in `query_utils.py` lines 90-95 and preserve the ordinary lookup
case.

PO-8: `Exists` is represented by `condExpr` in the mini semantics because
`Exists.output_field` is `BooleanField`, making its `conditional` property true.
The resulting `exprQ` has an expression child, and the audited source path in
`Query.build_filter()` accepts conditional expressions with `resolve_expression`.

PO-9: `Q._combine()` and `Q.deconstruct()` signatures are unchanged; no public
override or caller update is required.

## Test recommendation

No tests were edited. Because the proof is not machine-checked, no test removal
is recommended. If the K commands later return `#Top`, construction-level tests
for `Q() & Exists(...)` and `Q(...) & Exists(...)` would be subsumed by the
claims, but ORM integration tests should remain because this proof does not
cover SQL execution or backend behavior.

## Reproduce the machine check later

The following commands are recorded for a real K environment. They were not run.

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/q-combine-spec.k
kprove fvk/q-combine-spec.k
```

Expected result after machine checking: `#Top` for all claims.

## Residual risk

The trusted base is the adequacy of the mini semantics, K reachability logic,
and the future `kprove` run. This proof is partial correctness over the
combination/deconstruction fragment only; it does not prove all ORM filtering
behavior or database execution.

