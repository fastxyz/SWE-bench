# FVK Notes

## Decision

V1 stands unchanged in `repo/pylint/config/argument.py`.

The audit found no source-code defect against the FVK spec. The only edits in this phase are FVK artifacts under `fvk/` and this report.

## Trace to findings and obligations

- Kept brace-aware comma handling because F-002 shows V1 satisfies the reported `(foo{1,3})` case, discharging O2, O3, and O6.
- Kept top-level comma splitting because F-003 shows `foo,bar` still emits two fragments, discharging O3, O4, O5, and O7.
- Kept escaped-comma handling because F-004 traces directly to the issue's requested escape workaround and discharges O2 and O3.
- Kept the transformer structure because F-005 confirms the `"regexp_csv"` type key, return shape, and compile-through-`_regex_transformer` behavior satisfy O8, O9, and O10.
- Rejected the existing `test_csv_regex_error` behavior as a source-code constraint because F-001 classifies it as SUSPECT legacy behavior: it expects exactly the split that the public issue reports as the bug.
- Did not update documentation in this source fix because F-006 is a non-blocking documentation gap, not a correctness failure of the parser against the issue. The follow-up is recorded in `fvk/ITERATION_GUIDANCE.md`.

## Artifact corrections during FVK

- Added `fvk/mini-regex-csv.k` and `fvk/regex-csv-spec.k` to satisfy the FVK formal-core requirement.
- During static review, corrected the K fragment to append commas while in brace or character-class context; this was a formal-model gap, not a Python-source issue.
- Added concrete helper equations for `strip`, `nonEmpty`, and `snoc` over the modeled character language so the example claims do not rely on uninterpreted helpers.

## Verification status

No tests, Python, or K tooling were run, per task constraints. The proof is constructed, not machine-checked. The emitted commands in `fvk/PROOF.md` are the commands a human could run later in an environment with K installed.
