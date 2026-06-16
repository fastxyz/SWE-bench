# FVK Iteration Guidance

## Decision

Keep V1 production code unchanged. The audit found no formula, dispatch, support,
or compatibility defect requiring a V2 source edit. This decision is justified
by F-1 through F-4 and PO-1 through PO-5.

## Recommended Follow-Up Tests

Do not edit tests in this task. If tests are added later, they should cover the
public examples from `benchmark/PROBLEM.md`:

- `cdf(Arcsin("x", 0, 3))(1)` returns the arcsin closed form, not an Integral.
- `cdf(Dagum("x", S(1)/3, S(1)/5, 2))(3)` returns the Dagum closed form.
- `cdf(Erlang("x", 1, 1))(1)` returns a symbolic gamma expression or its exact
  simplification, not a Float from integration.
- `cdf(Frechet("x", S(4)/3, 1, 2))(3)` returns `exp(-1)`.
- `cdf(Gamma("x", 0.1, 2))(3)` returns a lowergamma expression rather than a
  partially evaluated Integral.
- `cdf(GammaInverse("x", S(5)/7, 2))(3)` returns an uppergamma expression.
- `cdf(Kumaraswamy("x", S(1)/123, 5))(S(1)/3)` returns the elementary formula.
- `cdf(Laplace("x", 2, 3))(5)` returns the positive-side Laplace branch.
- `cdf(Logistic("x", 1, 0.1))(2)` returns the logistic CDF without exception.
- `cdf(Nakagami("x", S(7)/3, 1))(2)` returns a lowergamma expression.
- `cdf(StudentT("x", 10))(2)` returns the hypergeometric CDF expression.
- `cdf(UniformSum("x", 5))(2)` returns the finite-sum CDF expression.

## Machine-Checking Guidance

Keep all tests until any future K artifacts are materialized and `kprove`
returns `#Top`. The current proof is constructed, not machine-checked.

## Next Code Pass

No next code pass is recommended for this issue. If future evidence shows a
problem, localize it against the proof obligations:

- dispatch or fallback issue: PO-1;
- wrong formula: PO-2;
- endpoint or support issue: PO-3;
- Erlang regression: PO-4;
- API compatibility issue: PO-5.
