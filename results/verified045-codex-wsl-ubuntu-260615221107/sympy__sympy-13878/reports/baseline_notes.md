# Baseline Notes

## Root Cause

Several continuous distributions in `sympy.stats.crv_types` did not implement
distribution-specific `_cdf` methods, so `SingleContinuousDistribution.cdf`
fell back to integrating the PDF symbolically. For these PDFs, integration is
slow, incomplete, can hang, or can return inexact numeric forms. A few affected
classes also exposed an overly broad or incorrect support interval, which made
fallback CDF integration start from the wrong lower bound.

## Files Changed

- `repo/sympy/stats/crv_types.py`
  - Added imports for `asin`, `uppergamma`, and `hyper`.
  - Added closed-form `_cdf` methods for Arcsin, Dagum, Frechet, Gamma,
    GammaInverse, Kumaraswamy, Laplace, Logistic, Nakagami, StudentT, and
    UniformSum distributions.
  - Corrected affected support metadata for Arcsin, Dagum, Frechet, and
    Kumaraswamy so their domains match the documented support.
  - Erlang uses `GammaDistribution`, so the new Gamma `_cdf` covers Erlang as
    well.
- `reports/baseline_notes.md`
  - Added this implementation note with the required root cause, change list,
    assumptions, and rejected alternatives.

## Assumptions

- The distribution parameters satisfy the documented positivity and support
  constraints; this matches the existing parameter validation style, which only
  raises when a constraint is explicitly false.
- CDF endpoint branches should avoid evaluating singular formulas where the
  PDF or closed form contains terms like `b/x` or `((x - m)/s)**(-a)`.
- Returning symbolic special-function forms such as `lowergamma`,
  `uppergamma`, and `hyper` is preferred over forcing simplification or numeric
  evaluation.

## Alternatives Considered

- Improving generic integration was rejected because the issue asks for
  precomputed CDFs, and the failure cases are distribution-specific.
- Rewriting PDFs as `Piecewise` functions was rejected as broader than needed;
  the CDF dispatch path only needs `_cdf` formulas and correct support metadata.
- Adding tests was not done because the task explicitly forbids modifying test
  files and hidden tests are fixed by the benchmark.
