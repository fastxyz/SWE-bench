# FVK Findings

Status: V1 stands. No additional source edit is required by the FVK audit.

## F1: invalid product-over-addition rule

- Classification: code bug in pre-V1, fixed by V1.
- Public evidence: `benchmark/PROBLEM.md` says the responsible line assumes the
  product of a sum is the sum of the products of its summands.
- Input: `Product(k**(S(2)/3) + 1, (k, 0, n - 1)).doit()`.
- Pre-V1 observed behavior: simplified to `1`.
- Expected behavior: no false closed form; return a sound result or an
  unevaluated `Product`.
- FVK trace: PO1 and C1 make numeric denominator-product additive branches
  return `None`; PO4 and C5 map that to unevaluated `Product`.
- Status: resolved by V1.

## F2: reported q-exponential product

- Classification: code bug in pre-V1, fixed by V1.
- Public evidence: `benchmark/PROBLEM.md` reports
  `Product(n + 1/2**k, (k, 0, n - 1)).doit()` produced a symbolic expression
  whose `n = 2` substitution is `9/2`, but the product is `15/2`.
- Input: `Product(n + 2**(-k), (k, 0, n - 1)).doit()`.
- Pre-V1 observed behavior: false sum of independently computed products.
- V1 expected behavior: the symbolic product remains unevaluated because no
  sound q-Pochhammer form is available in this checkout.
- FVK trace: PO2, PO4, and PO5 derive the issue path to `None` and then to the
  documented unevaluated fallback.
- Status: resolved by V1.

## F3: rational-product compatibility risk

- Classification: compatibility obligation, satisfied by V1.
- Public evidence: public tests under `test_rational_products` expect
  `product(1 + 1/n, (n, a, b))` and related rational products to evaluate.
- Risk: a too-broad fix could disable denominator-clearing rational products.
- Expected behavior: if `as_numer_denom()` creates an evaluable numerator and a
  nonnumeric evaluable denominator product, return their quotient.
- FVK trace: PO3 and C4 preserve the quotient path.
- Status: satisfied by V1.

## F4: q-Pochhammer closed form is an enhancement boundary

- Classification: underspecified / enhancement boundary, not a required edit.
- Public evidence: the prompt says the correct expression involves a
  q-Pochhammer symbol.
- Repository evidence: this checkout exposes ordinary RisingFactorial /
  Pochhammer references but no q-Pochhammer implementation.
- Expected behavior for this bug fix: use the public unevaluated `Product`
  fallback rather than adding a broad new special-function API.
- FVK trace: SPEC_AUDIT enhancement boundary and PO4.
- Status: no code change required.

## F5: constructed proof was not machine-checked

- Classification: proof/honesty residual risk.
- Evidence: task instructions prohibit running K tooling, tests, or Python.
- Expected behavior: artifacts include exact future `kompile`, `kast`, and
  `kprove` commands; no test deletion is recommended.
- FVK trace: `PROOF.md` machine-check section.
- Status: open operational caveat, not a source-code defect.

