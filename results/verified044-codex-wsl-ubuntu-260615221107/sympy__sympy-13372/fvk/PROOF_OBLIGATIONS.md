# FVK Proof Obligations

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## PO1: Successful fallback tuples are well formed

- Intent links: INT-4, INT-5.
- Claim: whenever the generic fallback returns normally, `re` and `im` are
  either mpf tuples or `None`, and the precision fields describe those
  components.
- Evidence in V1: exact-zero branches assign the component to `None`; numeric
  branches convert through `_to_mpmath(...)._mpf_`; symbolic branches raise
  before tuple assembly.
- K claims: `fallback(zero, zero)`, `fallback(zero, num)`,
  `fallback(num, zero)`, and `fallback(num, num)`.
- Status: discharged by inspection and by the constructed K claims.

## PO2: Symbolic nonzero components cannot reach tuple assembly

- Intent links: INT-1, INT-3, INT-4.
- Claim: if the fallback sees a real or imaginary component that is neither
  exact zero nor numeric, it raises `NotImplementedError` before `r = re, im,
  reprec, imprec`.
- Evidence in V1: both component classifiers now have an `else:
  raise NotImplementedError`.
- K claims: `fallback(sym, zero)` and `fallback(zero, sym)`.
- Status: discharged by inspection and by the constructed K claims.

## PO3: Numeric and exact-zero behavior is preserved

- Intent links: INT-5.
- Claim: V1 does not alter successful fallback behavior for components already
  covered by the original code: zero components still become `None`, numeric
  components still become mpf tuples with `prec`.
- Evidence in V1: no original branch body was changed; only missing `else`
  branches were added.
- Status: discharged by diff inspection.

## PO4: `NotImplementedError` reaches the public symbolic fallback

- Intent links: INT-2, INT-6.
- Claim: raising `NotImplementedError` from internal `evalf` is not exposed as
  the public result for ordinary `.evalf()`; public `EvalfMixin.evalf` catches it
  and falls back to `_eval_evalf`.
- Evidence in code: `EvalfMixin.evalf` wraps `result = evalf(...)` in
  `except NotImplementedError` and returns the ordinary symbolic value if
  recursive normalization also cannot make it numeric.
- Status: discharged by source inspection.

## PO5: `evalf_mul` preserves argument-order independence for unevaluable factors

- Intent links: INT-1, INT-2.
- Claim: if any `Mul` argument is unevaluable symbolically, internal
  `evalf_mul` can propagate `NotImplementedError`; public `.evalf()` then
  applies the ordinary fallback to the whole `Mul`, independent of which factor
  appeared first.
- Evidence in code: `evalf_mul` does not catch `NotImplementedError` around
  `evalf(arg, ...)`, and `EvalfMixin.evalf` catches it at the public boundary.
- Status: discharged by source inspection.

## PO6: The `prec=None` alternative is invalid

- Intent links: INT-4, INT-5.
- Claim: setting a precision variable to `None` for a symbolic component is not
  a valid fix.
- Reason: the tuple contract constrains the component slot, not only the
  precision slot. A symbolic `re`/`im` with `reprec=None` or `imprec=None` still
  violates callers' expectations; replacing the component with `None` would
  assert exact zero.
- Status: discharged as a design proof obligation; see F-2.

## PO7: Public compatibility is preserved

- Intent links: INT-6.
- Claim: V1 changes no public signature, no override protocol, and no return
  shape for successful numeric evalf results.
- Evidence: the diff adds only internal `else` branches in
  `sympy/core/evalf.py`.
- Status: discharged by diff/source inspection.

## PO8: Honesty gate

- Claim: proof results are constructed, not machine-checked; test removal is not
  justified.
- Evidence: task forbids running tests, Python, or K tooling.
- Status: open only as a tooling limitation; not a code blocker.
