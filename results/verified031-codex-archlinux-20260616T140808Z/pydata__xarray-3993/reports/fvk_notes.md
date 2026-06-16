# FVK Notes

## Decision Summary

V1 stands unchanged. The FVK audit found no additional production-code defect after checking the public intent, local source, public docs/tests, API compatibility, and constructed proof obligations.

## Decisions Traced to Findings and Proof Obligations

Kept the `coord` rename in `DataArray.integrate`.

- Finding trace: F-001 identifies the legacy mismatch as the issue's core bug.
- Obligation trace: PO-001 requires the public signature to use `coord`; PO-002 requires `coord=` to delegate the same operand.
- Decision: keep V1 unchanged because the method signature now names `coord` and the body calls `Dataset.integrate(coord, datetime_unit)`.

Kept the deprecated `dim=` compatibility wrapper.

- Finding trace: F-002 records the deprecation-cycle ambiguity and the public units-test helper that still uses `dim="x"`.
- Obligation trace: PO-004 requires `dim=` to normalize to `coord=` while signaling deprecation.
- Decision: keep V1 unchanged because the wrapper emits `FutureWarning`, moves `dim` to `coord`, and then follows the same delegation path.

Kept the duplicate-name `TypeError`.

- Finding trace: F-003 records the ambiguity created if callers supply both coordinate names.
- Obligation trace: PO-005 requires duplicate coordinate operands to be rejected.
- Decision: keep V1 unchanged because the wrapper raises before delegation when `dim` is paired with a positional coordinate or `coord=`.

Kept numerical integration code untouched.

- Finding trace: F-004 records the frame-condition risk that an API rename could accidentally change the numerical path.
- Obligation trace: PO-006 requires trapezoid arithmetic, coordinate validation, datetime handling, coordinate dropping, dask preservation, and reconstruction to remain owned by `Dataset.integrate`.
- Decision: no source edits were made because V1 already leaves `Dataset.integrate` and `_integrate_one` unchanged and delegates all normalized calls to that implementation.

Did not remove or modify tests.

- Finding trace: F-005 records that formal tooling was not executed.
- Obligation trace: all proof obligations are constructed but not machine-checked.
- Decision: no tests were edited, and `fvk/PROOF.md` / `fvk/ITERATION_GUIDANCE.md` recommend only future tests, not removals.

## Artifact Decisions

I wrote the requested five FVK artifacts under `fvk/`: `SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`, `PROOF.md`, and `ITERATION_GUIDANCE.md`.

I also added `fvk/mini-python-api.k` and `fvk/dataarray-integrate-spec.k` because the FVK documentation says a Markdown-only run is invalid. These K files model the API argument-normalization layer rather than the whole xarray numerical implementation; PO-006 records numerical integration as an unchanged frame condition.

## Commands Not Run

Per the benchmark instructions, I did not run tests, Python, `kompile`, `kast`, or `kprove`. The commands to run later are recorded in `fvk/PROOF.md` and `fvk/ITERATION_GUIDANCE.md`.
