# FVK Findings

Status: constructed, not machine-checked.

## F1: pre-fix branch order skipped the marker-skip rewrite

Classification: code bug, fixed by V1.

Evidence: `benchmark/PROBLEM.md` reports that `pytest -rs --runxfail` produced
`src/_pytest/skipping.py:238` for a test skipped by `@pytest.mark.skip`, while
the expected location was the test item.

Observed pre-fix path: a marked skip raises during setup, `reports.py` creates a
skipped report with `longrepr` at the internal raise site, then the old
`pytest_runtest_makereport` conditional stopped at the standalone
`elif item.config.option.runxfail: pass` branch before reaching the marker-skip
rewrite.

Expected path: `runxfail` suppresses only xfail-specific handling; the marked
skip branch remains reachable and rewrites the report location to the item.

Resolution: V1 guards the xfail-specific branches with
`not item.config.option.runxfail` and removes the standalone early `runxfail`
branch. This satisfies PO1 and PO2.

## F2: no additional source defect found in the audited behavior

Classification: confirmed behavior.

Evidence: K claim C1 and proof obligation PO2 cover the reported `runxfail`
marked-skip path. C2 covers the non-marker skip frame condition. C3 and C4 cover
the xfail-specific guard/frame behavior touched by V1.

Decision: no V2 source edit is justified. V1 stands unchanged.

## F3: proof is constructed, not machine-checked

Classification: proof capability gap.

Evidence: the task forbids running K tooling, and the FVK MVP itself labels
proofs as constructed until `kprove` returns `#Top`.

Expected next check: run the commands recorded in `fvk/SPEC.md` and
`fvk/PROOF.md` in an environment with K installed. Do not remove tests based on
this proof until that machine check succeeds.
