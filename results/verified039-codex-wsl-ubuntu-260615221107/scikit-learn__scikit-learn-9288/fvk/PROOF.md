# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`,
`kast`, or `kprove` were run.

## Machine-Check Commands

These commands are recorded for a future environment with K installed:

```sh
cd fvk
kompile mini-kmeans.k --backend haskell
kast --backend haskell kmeans-seeding-spec.k
kprove kmeans-seeding-spec.k
```

Expected machine-check result if the mini semantics and claims are accepted:
`#Top`.

## Proof Summary

Let `S = drawSeeds(rng, n_init)` be the ordered seed list generated from the
public `random_state`. Let `Run(s) = runSingle(params, s)` be the result of one
KMeans initialization for fixed validated inputs and seed `s`. Let
`Best(results)` be the first result with minimal inertia.

V1 computes `S` once before the serial/parallel split. The serial branch
iterates over `S` and maintains the first minimal-inertia result. The parallel
branch maps `Run` over `S` and applies `np.argmin` to the inertia list, also
choosing the first minimal-inertia result. Therefore both branches return:

```text
Best([Run(s) for s in S])
```

Thus, for all valid in-domain inputs and if the inner KMeans runs terminate,
the final labels, centers, inertia, and iteration count selected by `k_means`
are independent of `n_jobs`.

## Symbolic Proof Sketch

1. By PO-1, both branches start with the same seed list `S`.

2. Serial branch:
   - Base case: with no consumed seeds, the best accumulator is empty.
   - Step: consuming seed `s` computes `R = Run(s)`. If `inertia(R)` is lower
     than the accumulator, `R` becomes the accumulator; otherwise the
     accumulator is preserved.
   - Invariant C3: after consuming a prefix, the accumulator equals the first
     minimal-inertia result over that prefix.
   - Exit: after consuming all of `S`, serial returns `Best(mapRun(params, S))`.

3. Parallel branch:
   - The job generator enumerates `for seed in seeds`.
   - Each task computes `Run(seed)`.
   - The ordered result list is `mapRun(params, S)`.
   - `np.argmin(inertia)` selects the first minimal-inertia index.
   - Parallel returns `Best(mapRun(params, S))`.

4. By transitivity, both branches reach the same postcondition:
   `chooseBest(mapRun(params, drawSeeds(rng, n_init)))`.

## Adequacy and Completeness

The proof covers the full public defect: result dependence on `n_jobs` caused by
different random seeds for `n_init` runs. It also covers the order-sensitive tie
case because both branches select the first minimal inertia from the same
ordered results.

The proof does not establish total correctness or the mathematical correctness
of Lloyd/Elkan updates. Those are outside the reported defect and are framed as
the deterministic `runSingle(params, seed)` abstraction.

## Residual Risk

- Constructed, not machine-checked: the K commands above were not run.
- The mini semantics abstracts NumPy, SciPy, joblib, and the numeric KMeans
  inner loops.
- The proof assumes ordered result delivery from joblib `Parallel`, matching
  how the existing implementation consumes `results`.
- Test removal is not recommended. Existing and future tests should be kept
  unless the K claims are machine-checked and broader integration coverage is
  separately assessed.

## Test Guidance

No tests were modified or run. If test edits were allowed in a normal
development setting, the proof suggests adding regression coverage that checks
`KMeans(..., random_state=r, n_jobs=1)` and `n_jobs>1` select the same result
for representative `init` and `algorithm` choices. Keep integration,
performance, invalid-input, and numeric-convergence tests because this proof
does not subsume them.
