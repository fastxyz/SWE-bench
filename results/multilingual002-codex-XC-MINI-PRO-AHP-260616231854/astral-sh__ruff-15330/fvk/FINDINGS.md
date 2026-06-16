# FVK Findings

Status: V1 is confirmed against the FVK spec. No additional production-code edit is justified by
the public evidence and proof obligations.

## F1 - Closed: trailing comments no longer invalidate the script metadata block

Evidence: `benchmark/PROBLEM.md` reports false positives on `# dependencies = [` and `# ]` inside
inline script metadata when ordinary comments follow the closing `# ///`. The shared parser in
`ruff_python_ast::script` selects the last content line equal to `///` as the closing pragma.

Observed in V1: `skip_script_comments` scans the valid embedded-content prefix and assigns
`end_offset = Some(line.full_end())` for every `content == "///"`, so a later ordinary comment line
does not erase the selected delimiter.

Expected: the metadata comments through the selected delimiter are skipped before ERA001 detection.

Trace: PO3 and PO5.

Decision: V1 satisfies this finding; no source change required.

## F2 - Closed: unclosed inline script comments still do not suppress ERA001

Evidence: existing source comments state "Unclosed blocks MUST be ignored," and existing fixtures
include an unclosed script tag as an error case. The public issue concerns a closed block, not
loosening unclosed-block behavior.

Observed in V1: `skip_script_comments` returns `false` when the scan never sees a delimiter.

Expected: normal ERA001 analysis continues for unclosed blocks.

Trace: PO6.

Decision: V1 preserves the intended frame condition; no source change required.

## F3 - Closed: non-script comments outside the selected skip range remain checked

Evidence: the `ERA001` rule's public purpose is to find commented-out Python code. The issue only
identifies metadata lines inside an inline script block as false positives.

Observed in V1: after a valid block, the iterator consumes comments with `comment.start() <
end_offset`; comments at or after the selected closing delimiter's full end are left for the normal
ERA001 path.

Expected: suppression is limited to the opening tag and comments through the selected delimiter.

Trace: PO4 and PO7.

Decision: V1's narrower suppression is intentional and avoids hiding unrelated commented-out code.

## F4 - Residual: proof and tests were not executed

Evidence: the task forbids running tests, Python, Ruff, or K tooling.

Observed: the FVK proof is constructed, not machine-checked. No test redundancy recommendation can
be acted on in this session.

Expected: emit commands and reasoning only.

Trace: PO8.

Decision: no code implication; keep all tests.
