# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "When `@pytest.mark.skip`/`skipif` marks are used to skip a test" | Domain includes skip and skipif marks that skip during setup. | Encoded in SPEC and K claim C1. |
| E2 | prompt | Expected `SKIPPED [1] test_it.py:3: unconditional skip` | Marked skip reports use item definition location. | Encoded in SPEC and K claim C1. |
| E3 | prompt | Buggy output `src/_pytest/skipping.py:238` | Internal pytest raise location is the pre-fix symptom, not intended behavior. | Finding F1, fixed by V1. |
| E4 | prompt | "`--runxfail` is only about xfail and should not affect this at all" | `runxfail` must not block marker-skip location correction. | Encoded in SPEC and K claim C1. |
| E5 | code | `skipped_by_mark_key` is set when skip marks trigger | Marker-driven skips are distinguishable from runtime skips. | Encoded as model cell `skippedbymark`. |
| E6 | code | `reports.py` stores skip exception crash site in `longrepr` | The hook must rewrite `longrepr` after report creation. | Encoded in model as `internalSkip(R)`. |
| E7 | code | `pytest_runtest_makereport` xfail branches mutate outcome/wasxfail | Guard changes must preserve non-runxfail xfail behavior. | Covered by PO3 and K claim C4. |
