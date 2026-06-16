# Spec Adequacy Audit

Status: constructed, not machine-checked.

| Formal claim | Intent entries | Adequacy result | Notes |
| --- | --- | --- | --- |
| `hist-range-density` | I-001, I-002, E-001, E-002, E-003, E-005, E-006, E-007 | PASS | Directly states the issue fix: preserve explicit range while adding density on the non-stacked single-dataset path. |
| `hist-range-normed` | I-004, E-008 | PASS | `normed` compatibility follows the docstring and existing effective-density code. |
| `hist-range-no-density` | I-003, E-004 | PASS | Preserves the path the issue says already worked. |
| `hist-stacked-frame` | I-005, E-009 | PASS | Avoids changing stacked density's manual normalization semantics. |
| `hist-multi-density-frame` | I-006 | PASS | Models the existing shared-bin strategy for multiple datasets and does not require a range kwarg after bins are precomputed. |

## Coverage check

The claims cover the intent slice that V1 changed: construction of
`hist_kwargs` for `range`, `density`, `normed`, and `stacked`.

The claims do not prove NumPy's internal endpoint computation, rendering,
patch creation, log scaling, cumulative histograms, unit conversion, or
autoscaling. Those are outside this fix's mechanism and remain conventional
integration coverage.

No claim preserves the issue's pre-fix printed output. That output is marked
SUSPECT in the public evidence ledger because the issue identifies it as
buggy.
