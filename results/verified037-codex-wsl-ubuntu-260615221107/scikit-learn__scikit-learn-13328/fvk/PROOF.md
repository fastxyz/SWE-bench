# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove`
commands were run.

## Claims Proved in the Model

C-001: For every valid dense or accepted CSR boolean predictor matrix,
`fitV1` converts the dtype to `float64` before `gradientSquared`; the modeled
error cell remains `noError`.

C-002: For every valid dense or accepted CSR predictor matrix with dtype in
`FLOAT_DTYPES`, `fitV1` preserves the dtype before `gradientSquared`; the
modeled error cell remains `noError`.

C-003: The diagnostic pre-fix path `fitV0` forwards boolean `X` to
`gradientSquared`, and the modeled error cell becomes
`boolNegativeTypeError`.

## Proof Sketch

For C-001, start from:

```k
<k> fitV1(matrix(S, bool, R, C)) </k>
<validatedDType> unknownDType </validatedDType>
<error> noError </error>
```

with `R >=Int 1` and `C >=Int 1`.

The `fitV1` non-floating validation rule applies because
`isFloatDType(bool) => false`. It rewrites the computation to:

```k
gradientSquared(matrix(S, float64, R, C))
```

and rewrites `<validatedDType>` to `float64`. The
`gradientSquared` floating rule applies because
`isFloatDType(float64) => true`, ending the slice at `.K` while leaving
`<error>` as `noError`. By transitivity, the initial state reaches the claimed
post-state.

For C-002, start from:

```k
<k> fitV1(matrix(S, DT, R, C)) </k>
```

with `isFloatDType(DT)`. The `fitV1` floating validation rule applies and
preserves `DT`. The `gradientSquared` floating rule then applies under the same
side condition and leaves `<error>` as `noError`.

For C-003, start from the counterfactual pre-fix path:

```k
<k> fitV0(matrix(S, bool, R, C)) </k>
```

The `fitV0` rule forwards the boolean matrix unchanged to
`gradientSquared`. The boolean-gradient rule applies and rewrites `<error>` to
`boolNegativeTypeError`, matching the public issue's failure mechanism.

No loop circularity is required because the verified dtype-safety slice has no
loop in the formal model.

## Adequacy Gate

`INTENT_SPEC.md` requires boolean predictors through public `fit` to be
converted to float and not raise the reported TypeError. `FORMAL_SPEC_ENGLISH.md`
paraphrases the K claims with the same behavior, and `SPEC_AUDIT.md` marks the
claim-to-intent mapping as pass. `PUBLIC_COMPATIBILITY_AUDIT.md` finds no
public signature, override, or producer/consumer incompatibility.

Therefore the constructed proof supports `V2 == V1` for this issue's public
intent.

## Residual Risk

This is a partial, dtype-safety proof over a mini-Python abstraction. It does
not verify:

- SciPy optimizer termination or convergence;
- exact Huber coefficients, intercept, scale, or outlier mask;
- warnings and convergence-error behavior;
- public prediction behavior after fitting.

Those behaviors remain covered by conventional tests and source review.

## Machine-Check Commands Not Run

These commands are the exact intended FVK commands for a later environment with
K installed:

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell huber-fit-spec.k
kprove huber-fit-spec.k
```

Expected result after successful machine checking: `#Top` for all claims.

## Test-Redundancy Recommendation

No test files were modified. After machine checking, a narrow unit test that
only asserts the dtype-safety property for an in-domain boolean dense or CSR
matrix would be subsumed by C-001. Existing numerical, sparse, convergence, and
integration tests should be kept because they are outside this proof's scope.
