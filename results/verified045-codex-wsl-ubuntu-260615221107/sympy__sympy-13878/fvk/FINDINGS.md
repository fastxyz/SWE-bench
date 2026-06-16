# FVK Findings

Status key: `closed` means V1 source already addresses the finding; `open`
means a remaining issue or limitation.

## Closed Findings

- F-1, code bug, closed by V1.
  Evidence: INT-1 and INT-2 require precomputed CDFs because integration hangs,
  returns unevaluated integrals, returns partial integrals, or raises for the
  listed examples. `SingleContinuousDistribution.cdf` returns `_cdf(x)` before
  integration when no kwargs are supplied.
  Static result: V1 adds `_cdf` methods for every listed distribution class, and
  Gamma covers Erlang through the existing `Erlang` constructor.
  Trace: PO-1, PO-2, PO-4.

- F-2, support metadata mismatch, closed by V1.
  Evidence: INT-6 states bounded or shifted supports for Arcsin, Frechet, and
  Kumaraswamy, and positive support for Dagum. The pre-V1 fallback either used
  the inherited all-real support or a stale support for some classes.
  Static result: V1 sets Arcsin support to `Interval(a, b)`, Dagum to
  `Interval(0, oo)`, Frechet to `Interval(m, oo)`, and Kumaraswamy to
  `Interval(0, 1)`.
  Trace: PO-3.

- F-3, formula adequacy, closed by V1.
  Evidence: INT-4 and INT-5 require symbolic closed forms. For each V1 formula,
  differentiating the in-support branch gives the class PDF, and support
  branches give 0 below support and 1 above bounded support.
  Static result: no formula mismatch was found during the algebraic audit.
  Trace: PO-2, PO-3.

- F-4, API compatibility, closed by V1.
  Evidence: INT-1 asks for internal `_cdf` methods. V1 does not change public
  constructor signatures, `cdf` dispatch, or test files.
  Static result: compatibility obligations are satisfied by additive methods and
  import additions only.
  Trace: PO-5.

## Open Limitations

- F-5, proof capability gap, open.
  Evidence: the task forbids tests, Python execution, and K tooling. This audit
  is constructed from source and algebraic reasoning only.
  Expected vs observed: expected machine-checked proof would end with `kprove`
  returning `#Top`; observed state is no tool execution.
  Trace: PO-6.

- F-6, total correctness/performance, open but non-blocking.
  Evidence: FVK defaults to partial correctness, and the intent is to avoid the
  integration fallback for default CDF calls. The proof does not establish
  termination or simplification performance for downstream SymPy operations on
  returned formulas.
  Trace: PO-6.

## V2 Decision

No V2 production code edit is justified by these findings. Findings F-1 through
F-4 are closed by V1, and F-5 through F-6 are proof/tooling limitations rather
than source defects.
