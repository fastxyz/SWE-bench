# Iteration Guidance

Status: V1 stands unchanged.

## Decision

Keep the V1 source patch in `repo/sphinx/cmd/quickstart.py`.

The FVK audit did not surface a blocking source defect. The direct status-1
existing-project exit is justified by the public hint and discharges the
reported empty-input failure. The replacement-root retry prompt is classified as
SUSPECT legacy behavior because it is quoted as part of the buggy interaction.

Trace:

- F1 and PO2 show the root-level `conf.py` failure is closed.
- F2 and PO4 justify not restoring the replacement-root prompt.
- F3 and PO3 show `source/conf.py` remains covered.
- PO7 shows no public compatibility blocker.

## Suggested next tests

Do not add tests in this task. In a normal development pass, add public tests for:

- interactive `main()` with existing `conf.py` returns `1` and does not ask for a
  replacement path;
- interactive `main()` with existing `source/conf.py` returns `1`;
- a non-conflict root still continues through the normal prompts.

## Residual risk

The proof is constructed, not machine-checked. The mini-K model intentionally
abstracts away argparse, localization, terminal coloring, and the later
questionnaire. Those are acceptable frame abstractions for this patch because
the changed branch occurs after the selected root exists and before later
questions or generation.
