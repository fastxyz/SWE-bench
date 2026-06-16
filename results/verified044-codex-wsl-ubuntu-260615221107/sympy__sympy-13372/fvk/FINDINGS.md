# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## F-1: V1 removes the reported uninitialized-local failure

- Evidence: INT-1, PO2.
- Input class: an object with no `evalf_table` handler whose `_eval_evalf`
  result has a symbolic nonzero real or imaginary part, such as the `Max(0, y)`
  factor in `Mul(Max(0, y), x, evaluate=False).evalf()`.
- V0 observed: `reprec` or `imprec` could be read before assignment.
- V1 expected/observed by inspection: the symbolic component branch raises
  `NotImplementedError` before tuple assembly.
- Classification: code bug fixed by V1.

## F-2: `prec=None` is not a sound substitute for `NotImplementedError`

- Evidence: INT-4, INT-5, PO1, PO6.
- Input class: symbolic nonzero component with the other component exact zero,
  modeled as `fallback(sym, zero)` or `fallback(zero, sym)`.
- Rejected alternative: assign only `reprec = None` or `imprec = None` and
  continue.
- Why rejected: the tuple would still contain a symbolic expression where
  downstream code expects an mpf tuple or `None`. Assigning the component itself
  to `None` would instead misclassify an unevaluable symbolic value as exact
  zero.
- Classification: candidate alternative rejected; no V2 edit needed.

## F-3: The argument-order symptom is explained by fallback propagation

- Evidence: INT-2, PO4, PO5.
- Input class: `Mul` with at least one unevaluable symbolic factor.
- V0 observed: when `x` was first, the symbol path raised
  `NotImplementedError` early and public `evalf` returned the ordinary symbolic
  reconstruction; when `Max(0, y)` was first, the incomplete fallback crashed
  before the same mechanism could operate.
- V1 expected/observed by inspection: both orders can leave internal numeric
  evalf through `NotImplementedError`, so the public fallback path is the same.
- Classification: code bug fixed by V1.

## F-4: Compatibility risk is low

- Evidence: PO7.
- Changed symbol: internal function `evalf(x, prec, options)`.
- API surface: no public signature or return shape changed for successful
  numeric results.
- Dispatch shape: no new arguments, no new virtual method calls, and no changes
  to `_eval_evalf` overrides.
- Classification: no compatibility blocker found.

## F-5: Residual verification limitations

- Evidence: PO8.
- The K proof is constructed but not machine-checked.
- No tests or Python snippets were run, by task instruction.
- The abstract K model verifies fallback classification and tuple shape, not
  mpmath numeric precision or all of SymPy evalf.
- Classification: proof/tooling limitation, not a source-code defect.

## Overall Finding

The FVK audit found no source-code problem requiring a V2 change. V1 is the
minimal fix justified by the public intent and proof obligations.
