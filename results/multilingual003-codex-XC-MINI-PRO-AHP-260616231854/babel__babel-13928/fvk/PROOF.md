# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, parser run, or test run was executed.

## Commands for later machine checking

```sh
kompile fvk/mini-parser-scope.k --backend haskell
kast --backend haskell fvk/parser-scope-spec.k
kprove fvk/parser-scope-spec.k
```

Expected result after a real machine check: `kprove` discharges the claims in `fvk/parser-scope-spec.k` to `#Top`.

## Proof of PO1

`parseFunctionBody` starts by entering an expression scope. In the concise-arrow-body branch, V1 parses the expression body, checks parameters, and exits that expression scope. In the mini semantics this is:

```k
parseConciseArrowBody => enter E ; exit
```

For any stack `S`, `enter E` rewrites `S` to `E :: S`, and `exit` rewrites `E :: S` back to `S`. By transitivity, `parseConciseArrowBody` preserves the stack shape. This proves the concise branch is balanced in the modeled state.

## Proof of PO2

Start in the enclosing function body with stack `E :: REST`.

Parsing the nested function parameters with the concise arrow default follows this modeled sequence:

```k
enter P ; parseArrowHead ; parseConciseArrowBody ; exit
```

`enter P` gives `P :: E :: REST`. `parseArrowHead` enters and exits `A`, returning to `P :: E :: REST`. By PO1, `parseConciseArrowBody` enters and exits `E`, also returning to `P :: E :: REST`. The final `exit` belongs to `parseFunctionParams`, so it pops `P` and leaves `E :: REST`.

The later `await` or `yield` calls `recordParameterInitializerError`. With top scope `E`, the modeled `recordParamInit` returns with outcome `ok`. This matches the public intent that the reported programs are valid.

## Proof of PO3

For a real parameter-initializer violation, the stack top is still `P` when `recordParameterInitializerError` runs. The mini semantics has:

```k
recordParamInit on P :: REST => paramError
```

V1 does not change the implementation of `recordParameterInitializerError`, `parseAwait`, or `parseYield`. Therefore the existing formal-parameter diagnostics remain reachable for actual parameter-list violations.

## Proof of PO4

The arrow-head path is before the V1 edit: `parseParenAndDistinguishExpression` calls `validateAsPattern()`, exits the arrow-head expression scope, then calls `parseArrowExpression`. The V1 line is inside `parseFunctionBody`, reached after this point. Therefore arrow-head validation order and recorded arrow-head errors are framed unchanged.

## Proof of PO5

The block-body branch already had an expression-scope exit. Since V1 adds an exit only to the `isExpression` branch and leaves the `else` branch untouched, block-body stack behavior is preserved. The mini claim `block-body-balance-preserved` captures this frame condition.

## Adequacy check

The formal claims say exactly the public intent needed for this issue:

- the reported programs are accepted because the later `await`/`yield` sees an expression boundary;
- real parameter errors still raise when the top scope is a parameter declaration;
- arrow-head validation and block-body cleanup are unchanged.

No claim relies on legacy behavior as an expected result. The legacy behavior appears only as F1's observed bug.

## Test-redundancy recommendation

No test files are modified or recommended for deletion. Because this proof is constructed but not machine-checked, any future test-redundancy decision would be conditional on running the commands above and obtaining `#Top`.
