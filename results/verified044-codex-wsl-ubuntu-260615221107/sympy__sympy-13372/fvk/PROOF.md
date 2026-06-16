# FVK Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Formal Core

Artifacts:

- `fvk/mini-evalf.k`: abstract K semantics for the changed fallback
  classifier.
- `fvk/evalf-fallback-spec.k`: K reachability claims for symbolic, numeric, and
  exact-zero component combinations.

Commands to machine-check later:

```sh
cd fvk
kompile mini-evalf.k --backend haskell
kast --backend haskell evalf-fallback-spec.k
kprove evalf-fallback-spec.k
```

Expected machine-check result if the abstract model and claims parse as written:
`#Top`. This expectation was not executed.

## Claim Paraphrase

The K claims say:

- `fallback(sym, zero)` reaches `notImplemented`.
- `fallback(zero, sym)` reaches `notImplemented`.
- `fallback(zero, zero)` reaches a tuple with both components exact-zero
  sentinels.
- `fallback(num, zero)` and `fallback(zero, num)` reach tuples with one mpf
  component and one exact-zero sentinel.
- `fallback(num, num)` reaches a tuple with both components mpf-valued.

These claims are the formal version of PO1 and PO2.

## Constructed Proof Sketch

1. Start from `fallback(RE, IM)`.
2. Case split on the real component.
3. If `RE = sym`, the `fallback(sym, IM)` rule rewrites directly to
   `notImplemented`; no precision variable is read and no tuple is assembled.
4. If `RE = zero`, the rule rewrites to `finishRe(noneVal, nonePrec, IM)`.
5. If `RE = num`, the rule rewrites to `finishRe(mpfVal, somePrec, IM)`.
6. Case split on the imaginary component in `finishRe`.
7. If `IM = sym`, the `finishRe(..., sym)` rule rewrites to
   `notImplemented`; again no tuple is assembled with a symbolic component.
8. If `IM = zero` or `IM = num`, the corresponding rule assembles a tuple whose
   component slots are only `noneVal` or `mpfVal`.

There are no loops, recursion, arithmetic verification conditions, or
termination obligations in the changed branch.

## Code-Level Proof

The source implementation mirrors the abstract rules:

- `if re == 0` corresponds to `RE = zero`.
- `elif re.is_number` corresponds to `RE = num`.
- `else: raise NotImplementedError` corresponds to `RE = sym`.
- The imaginary component uses the same three-way split.

The tuple assignment `r = re, im, reprec, imprec` is reachable only after both
components have taken either the exact-zero or numeric branch. Therefore V1
prevents the reported `UnboundLocalError` and also preserves the documented
tuple contract.

At the public boundary, `EvalfMixin.evalf` already catches
`NotImplementedError` from internal `evalf` and falls back to ordinary
`_eval_evalf`. `evalf_mul` does not catch `NotImplementedError` around argument
evaluation, so an unevaluable first factor and an unevaluable later factor both
reach the same public fallback mechanism. This discharges the argument-order
obligation for the reported `Mul` forms.

## Adequacy

The proof is not merely certifying the candidate behavior:

- The expected no-crash behavior comes from the issue report, not from V1.
- The symbolic preservation behavior comes from the non-crashing example in the
  issue and the existing public fallback path.
- The rejection of `prec=None` for symbolic values comes from the tuple contract
  in `evalf.py`, which says `None` components denote exact zero.

## Test Guidance

No tests were modified or run. If tests could be added in a normal development
environment, the useful public regressions would be:

- `Mul(Max(0, y), x, evaluate=False).evalf()` returns the same symbolic form as
  `Mul(x, Max(0, y), evaluate=False).evalf()`.
- A direct internal fallback over a nonzero symbolic real or imaginary component
  leaves the numeric path through `NotImplementedError`, not by constructing a
  tuple containing symbolic component values.

No existing tests are recommended for removal, because the proof is constructed
but not machine-checked and this task forbids editing tests.
