# PROOF

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, tests, Python, or Rust commands were run.

## Claims Proved by Construction

The proof is over the reduced state-machine semantics in `fvk/mini-ruff-logical-lines.k` and the claims in `fvk/definition-state-spec.k`.

### Claim 1: Issue E252 Branch Is False

Starting state:

```text
notInDefinition
```

Issue-shaped prefix:

```text
typeTok, nameTok, equalTok, nameTok, lsqbTok, newlineTok,
nameTok, commaTok, nameTok, lparTok, nameTok
```

Symbolic execution:

1. `typeTok` rewrites `notInDefinition` to `inTypeAlias(beforeTypeParams)`.
2. `nameTok` leaves the state unchanged.
3. `equalTok` rewrites `inTypeAlias(beforeTypeParams)` to `inTypeAlias(typeParamsEnded)`.
4. The RHS `lsqbTok`, newline, names, comma, and `lparTok` leave `typeParamsEnded` unchanged.
5. `isInTypeParams(inTypeAlias(typeParamsEnded))` rewrites to `false`.
6. `isE252MissingBranch(..., 2, false)` rewrites to `false orBool (false andBool false)`, which is `false`.

This discharges PO-01, PO-02, and PO-03.

### Claim 2: Actual Type Parameters Are Preserved

Prefix:

```text
typeTok, nameTok, lsqbTok, nameTok
```

Symbolic execution:

1. `typeTok` enters `inTypeAlias(beforeTypeParams)`.
2. `lsqbTok` before any alias assignment enters `inTypeAlias(inTypeParams(0))`.
3. `isInTypeParams(...)` is true.
4. `isE252MissingBranch(..., 1, false)` rewrites to true.

This discharges PO-04.

### Claim 3: Nested Type-Parameter Brackets Are Preserved

Prefix:

```text
typeTok, nameTok, lsqbTok, nameTok, equalTok, nameTok,
lsqbTok, nameTok, rsqbTok, rsqbTok
```

Symbolic execution:

1. The first `lsqbTok` enters `inTypeParams(0)`.
2. The nested `lsqbTok` increments the inner bracket count to `inTypeParams(1)`.
3. The first `rsqbTok` decrements the count to `inTypeParams(0)`.
4. The final `rsqbTok` ends type parameters as `typeParamsEnded`.

This discharges PO-05.

### Claim 4: Annotated Function Path Is Preserved

Prefix:

```text
defTok, nameTok, lparTok, nameTok, colonTok, nameTok
```

Symbolic execution:

1. `defTok` enters `inFunction(beforeTypeParams)`.
2. `lparTok` ends the type-parameter window as `inFunction(typeParamsEnded)`.
3. The consumer-side condition models the rule's annotated-function flag as true at paren depth 1.
4. `isE252MissingBranch(..., 1, true)` rewrites to true.

This discharges PO-06.

## Source Decision

The constructed proof supports keeping V1 unchanged. The V1 edit is exactly the transition needed by Claim 1 and does not disturb Claims 2-4.

## Machine-Check Commands

These commands are recorded for a proper K environment and were not executed:

```sh
kompile fvk/mini-ruff-logical-lines.k --backend haskell
kast --backend haskell fvk/definition-state-spec.k
kprove fvk/definition-state-spec.k
```

Expected machine-checked result: `#Top` for all claims.

## Test Recommendation

Do not remove tests in this benchmark task. If machine-checking later succeeds, a narrow public test asserting no `E252` for the reported `type MyType = Annotated[...]` form would be subsumed by Claim 1. Tests for real type-parameter defaults, annotated function parameters, parser integration, autofix application, and CLI reporting should be kept because this reduced proof does not cover full Ruff integration or formatting output.
