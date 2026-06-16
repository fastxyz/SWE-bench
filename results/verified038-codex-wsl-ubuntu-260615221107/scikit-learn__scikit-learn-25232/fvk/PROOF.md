# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## What Is Proved

Within the abstract model in `fvk/mini-python-impute.k`, the V1 fix satisfies
the public bug-fix contract:

- `IterativeImputer` stores the new `fill_value` constructor parameter.
- `_initial_imputation` forwards that exact value to `SimpleImputer`.
- `fill_value=None` is preserved so default behavior remains delegated to
  `SimpleImputer`.
- `initial_strategy="constant"` treats all features as valid even when the
  constant statistics are `np.nan`.
- Non-constant strategies keep the old non-NaN statistics filtering rule.

## Symbolic Proof Sketch

P-001 proves O-001.

The K rule
`<k> initIterative(F) => iterativeObj(F) ... </k>` rewrites the constructor
abstraction in one step. The right-hand object contains the same symbolic
fill value `F`, so the postcondition follows by reflexivity of the carried
symbol.

P-002 proves O-002.

The K rule
`<k> makeInitialImputer(S, F) => simpleObj(S, F) ... </k>` rewrites the
internal constructor abstraction in one step. Both strategy `S` and fill value
`F` are framed unchanged, matching the source call
`SimpleImputer(strategy=self.initial_strategy, fill_value=self.fill_value, ...)`.

P-003 proves O-003.

Given `N >= 0`, the term
`validMask(constant, N, constantStats(N, NaNFill))` matches the constant-rule
left side in `mini-python-impute.k`, so it rewrites directly to
`allIndices(N)`. The proof does not need to simplify `constantStats`; that is
the point of the V1 branch. Constant strategy does not inspect the statistics
for NaN-ness.

P-004 proves O-004.

For each non-constant strategy, the corresponding K rule rewrites
`validMask(S, N, STATS)` to `nonNanIndices(STATS, 0)`. The recursive definition
of `nonNanIndices` keeps index `I` exactly when `isNaN(F) ==Bool false` and
skips it otherwise, matching the previous `np.isnan(statistics_)` filter.

P-005 proves O-005.

The same constructor and internal-imputer rules from P-001 and P-002 are
instantiated with `F = NoneFill`. The result preserves `NoneFill`, proving that
the new code does not replace the default before `SimpleImputer` receives it.

## Adequacy Gate

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases every nontrivial claim.
`fvk/SPEC_AUDIT.md` compares those claims against `fvk/INTENT_SPEC.md`.
All audited claims pass. No proof obligation depends only on legacy behavior.

## Test-Redundancy Recommendation

No test files were modified. Because this benchmark forbids running tests and
the proof is not machine-checked, no test removal is recommended now.

If the emitted K commands later return `#Top`, targeted tests that merely
assert the following in-domain properties would be subsumed by the proof:

- `IterativeImputer(fill_value=F).fill_value == F`;
- `initial_strategy="constant"` forwards `F` to the internal
  `SimpleImputer`;
- `fill_value=np.nan` does not make the constant-strategy validity mask empty;
- non-constant strategies continue to use non-NaN statistic filtering.

Integration, estimator compatibility, numerical convergence, sparse-data, and
end-to-end tests should be kept.

## Reproduce The Machine Check Later

The following commands are emitted for a future environment with K installed.
They were intentionally not executed here.

```sh
cd fvk
kompile mini-python-impute.k --backend haskell
kast --backend haskell iterative-imputer-spec.k
kprove iterative-imputer-spec.k
```

Expected result after machine checking: `kprove` returns `#Top`.

