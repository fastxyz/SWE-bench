# FVK Proof

Status: constructed, not machine-checked. No tests, Python code, or K tooling were run.

## Target

Prove partial correctness of the local `Add._eval_is_zero` decision for the
zero-real-part imaginary cases described in `benchmark/PROBLEM.md`, plus the
public compatibility cases found in source tests.

## Proof Shape

The implementation scans `self.args` once and maintains these facts:

- `z`: count of known real zero terms.
- `nz`: known real nonzero terms.
- `im`: real coefficients of definitely imaginary terms, computed as `a*I`.
- `im_or_z`: whether a term is only known to be imaginary-or-zero.

Loop invariant over the scan prefix:

1. `z` contains only known real zero terms.
2. `nz` contains only known real nonzero terms and contributes the whole known
   real part of the prefix.
3. `im` contains exactly the definitely imaginary prefix terms, represented as
   real coefficients after multiplying by `I`.
4. `im_or_z` is true iff the prefix contains a term whose real part is known
   zero but whose zero status is not known.
5. Encountering an unsupported or unknown classification returns `None`.

The scan is finite over `self.args`; this proof is partial correctness and
does not separately prove termination of sub-assumption recursion.

## Case Proof

After the scan:

1. If all terms are known zero, returning `True` is sound.
2. If every term is a known real nonzero term, the handler returns `None`,
   preserving the "do not guess" intent because real terms can cancel.
3. Let `b = Add(*nz)` be the known-real part.
4. If `b.is_zero is False`, returning `False` is sound: purely imaginary or
   imaginary-or-zero terms cannot cancel a nonzero real part.
5. If `b.is_zero` and there are no imaginary terms and no imaginary-or-zero
   terms, returning `True` is sound.
6. If `b.is_zero`, there are definitely imaginary terms, and there are no
   imaginary-or-zero terms:
   - If the imaginary coefficient sum is known zero, returning `True` is sound.
   - If there is exactly one definitely imaginary term, returning `False` is
     sound because `0` is not imaginary.
   - If all coefficients are nonnegative and at least one is positive,
     returning `False` is sound because their sum is positive.
   - If all coefficients are nonpositive and at least one is negative,
     returning `False` is sound because their sum is negative.
   - Otherwise the code returns `None`.

These cases cover all V2 boolean returns in the audited region.

## Reported Expression

The reported expression has zero known-real part and two definitely imaginary
terms. The handler is not required to expand `(1 + I)**2` to prove exact zero.
Under the local model it has no same-sign certificate and no quick proof that
the imaginary coefficients sum to zero. V2 therefore falls through without a
boolean return and yields `None`.

This discharges the public obligation: the result is no longer the wrong
boolean `False`.

## V1 to V2 Improvement

V1 returned the coefficient-sum subquery result whenever it was not `None`.
The FVK audit rejected the multi-term `False` half of that rule as a larger
proof obligation than the local fix needed. V2 keeps only the `True` half,
which proves exact cancellation, and requires local non-cancellation evidence
for `False`.

This addresses Finding F2 and Proof Obligation PO3.

## K Claims

The constructed K claims in `fvk/add-is-zero-spec.k` encode:

- reported cancellation-possible class returns `U`;
- singleton imaginary class returns `F`;
- same-sign coefficient classes return `F`;
- nonzero known-real part returns `F`;
- known-zero imaginary coefficient sum returns `T`.

Expected machine-check commands, not run:

```sh
kompile fvk/mini-add-is-zero.k --backend haskell
kast --backend haskell fvk/add-is-zero-spec.k
kprove fvk/add-is-zero-spec.k
```

## Residual Risk

The proof is constructed, not machine-checked. It relies on the mini-model
faithfully representing the local decision and on the soundness of lower-level
SymPy assumption predicates when they return definite values.

No tests are recommended for deletion. Existing tests remain useful until the
K claims are machine-checked and conventional project tests can be run in an
environment that permits execution.
