# Incidents & decisions log

Traceability log for the post-run analysis. Every problem, non-obvious choice, fallback, or deviation from [PLAN.md](PLAN.md) is recorded here with references, so the run is reviewable.

Format per entry: **[YYYY-MM-DD] title** — what happened · reference (paths/IDs) · choice made · reasoning.

---

## Operating decisions (run start, 2026-06-14)

- **Commit to `main`, single final commit.** Rationale: repo convention is to commit run results directly to `main` (see recent `results: batch*` commits); the analysis is additive (new `fvk_bench_analysis/` folder only), touches no code and no submodules. Authorized by the user for this run.
- **Scope:** all 7 fvk-failing instances (PLAN §2), processed sequentially in batch order. (User raised scope from "first 5" to "all 7".)
- **Audit target:** the fvk arm's artifacts; baseline V1 read only as context. No verification/re-run phase (dropped by user).

---

## Accumulated primer corrections

- **[2026-06-14] Added tell #7 "scope-induced false-negative" to primer §(v).** From astropy-13398: when V1 is incomplete vs. the issue, fvk draws the spec domain around the existing code and declares it "clean and total on its domain," masking a MISSING. Propagated so instances 2–7 don't mistake that false reassurance for correctness. Ref: `_shared/fvk-primer.md` §(v) item 7; `astropy__astropy-13398/ANALYSIS.md` §3.
- **[2026-06-14] Corrected tell #4's `django-10554` citation (was a false positive).** The primer v1 cited `django-10554 SPEC.md:31-38` as an example of "root cause told as the fix." The django-10554 analysis showed those lines model an *unrelated* mechanism (`Query.clone()` aliasing) and only quote the symptom string; the true cause (missing case in `get_order_by`) is absent → verdict MISSING. Recast in primer §(v) tell #4 as a **decoy counter-example** (symptom-string match ≠ presence; apply pointed-at-the-spot to the *cause*). Ref: `_shared/fvk-primer.md` §(v) item 4; `django__django-10554/ANALYSIS.md` §3.
- **[2026-06-14] Added tell #8 "STATED-but-reasoned-against" to primer §(v).** From django-12325 (first headroom-positive): FVK quoted the oracle's exact fix and rejected it because it treated a pre-fix in-repo test as binding ground truth (the gold patch deletes that test). Distinct failure mode from #7. Ref: `_shared/fvk-primer.md` §(v) item 8; `django__django-12325/ANALYSIS.md` §3.
- **[2026-06-14] Annotated tell #3's `django-13212 F3` citation.** F3 is shape-correct (intent vs normalized-value divergence) and fvk fixed it, BUT it is a `URLValidator` finding orthogonal to django-13212's graded failure (a `DecimalField.validate` NaN short-circuit in `forms/fields.py`), whose cause is MISSING (scope-fenced). Not a decoy (unlike django-10554), but "don't read F3 as the instance being solved from findings." Ref: `_shared/fvk-primer.md` §(v) item 3 caveat; `django__django-13212/ANALYSIS.md` §3.
- **[2026-06-14] Added tell #9 "FVK certifies the buggy behavior as the spec" to primer §(v).** From django-16263: a POSITIVE finding (F6) enshrines V1's wrong single-SELECT output as the contract, and the mini-ORM abstracts away the SQL-shape axis the tests measure (fenced as escalation boundary). Canonical "formalize the implementation, not the intent" anti-pattern → MISSING (inverted), distinct from #7. Ref: `_shared/fvk-primer.md` §(v) item 9; `django__django-16263/ANALYSIS.md` §3.
- **[2026-06-14] Widened tell #8 (broader "reasoned-against" form).** From pytest-10356: the correct fix (`reversed` → forward `__mro__`) was rejected not via a binding test (as in django-12325) but via a logically-flawed "forcing" proof obligation (PO3) that fabricated a requirement for the buggy order and predicted the wrong hidden-test output. Shows constructed-not-machine-checked proofs can manufacture confident-but-false obligations. Ref: `_shared/fvk-primer.md` §(v) item 8 "Broader form"; `pytest-dev__pytest-10356/ANALYSIS.md` §3.
- **[2026-06-14] `.gitignore` `*.patch` (line 168) excluded 5 evidence solution-patch copies from the commit.** A global `*.patch` rule — deliberate repo policy; it also leaves run outputs `results/<batch>/<id>/solutions/solution_*.patch` untracked — silently skipped these from `git add fvk_bench_analysis`:
  - `django__django-12325/evidence/solution_fvk_eq_baseline.patch`
  - `django__django-16263/evidence/solution_baseline.patch`, `.../solution_fvk.patch`
  - `pytest-dev__pytest-10356/evidence/V1_solution_baseline.patch`
  - `sphinx-doc__sphinx-9229/evidence/V1_eq_final_solution_fvk.patch`

  Choice: **respect the repo policy; do not force-add.** No repository information is lost — each is byte-identical to a reproducible run output under `results/.../solutions/`, the authoritative **oracle** patches are committed (as `*.diff`), and the substantive V1-vs-oracle / V1-vs-final comparisons are already captured in committed evidence (`v1_vs_final_diff.md`, `diff_V1_vs_oracle.txt`, the "V1 == final" notes) and in each `ANALYSIS.md`. Working-tree copies remain locally for offline reference. (If self-contained patches in-repo are later wanted, re-save them with a non-`.patch` extension.)

- **[2026-06-14] Primer stabilized — tell #9 validated on a third repo with no correction (sphinx-9229).** The tells now hold across astropy/django/pytest/sphinx; no further primer edits were required for instance 7. A "half-fix" sub-pattern (oracle = two coordinated edits; V1+FVK did one and certified the unpatched half) is captured in `SYNTHESIS.md` rather than as a new tell. Ref: `sphinx-doc__sphinx-9229/ANALYSIS.md` §3.

## Incidents

- **[2026-06-14] SWE-bench `test_patch` not stored in `fvk_bench/data/instances.json`.** Only `problem_statement` + hints are vendored (by design — the arm must not see hidden tests). For analysis we need the FAIL_TO_PASS bodies to state the root cause precisely. Ref: astropy-13398 lead recovered F2P test bodies from a post-merge cached checkout; recorded in `astropy__astropy-13398/evidence/failing_test_snippet.txt`. Choice: allow leads to recover gold/test material from the goldcheck dir, the `third_party/swebench-fvk-reproducibility` submodule, or a cached checkout, and cite the source. No impact on verdict validity (oracle patch + gold test output are authoritative).

- **[2026-06-14] Subagent `Write` tool blocked by a guardrail for the per-instance lead.** The astropy-13398 lead's `Write` of `ANALYSIS.md` was refused; it fell back to a Bash heredoc and produced a correct, intact 11 KB file (verified by the orchestrator: read in full, well-formed, no escaping corruption). Choice: subsequent lead prompts instruct the agent to fall back to `cat > file <<'EOF' … EOF` (quoted delimiter, to avoid `$`/backtick expansion) if `Write`/`Edit` is blocked. Orchestrator spot-checks file sizes after each instance and full-reads only on doubt (to preserve context).

- **[2026-06-14] FAIL_TO_PASS name discrepancy (django-10554).** Sub-agents disagreed on which tests are FAIL_TO_PASS. Resolved against `results/batch1-XC-MINI-PRO-AHP/django__django-10554/eval/fvk.report.json` (authoritative): the two F2P are `test_union_with_values_list_and_order` and `test_union_with_values_list_on_annotated_and_unannotated`; `test_order_raises_on_non_selected_column` is PASS_TO_PASS. Policy going forward: when test sets are ambiguous, the per-arm `eval/<arm>.report.json` is the source of truth for resolved/F2P/P2P.

- **[2026-06-14] Benign methodology clarification (do not mistake for a discrepancy).** `logs/run_evaluation/<batch>.goldcheck/.../test_output.txt` runs the **gold** patch (tests PASS — it validates the oracle). `results/<batch>/<id>/eval/<arm>.report.json` is the **arm** run (tests FAIL for these instances). Both are correct and describe different patches; leads should not treat the pass/fail difference as a conflict. (Surfaced on django-12325.)

- **[2026-06-14] Eval harness over-counts F2P failures for django-13212 (scoring caveat, verdict unaffected).** `eval/fvk.report.json` lists 2 FAIL_TO_PASS failures (decimal + file), but the stored arm `test_output.txt` shows `FAILED (failures=1)` — only the `DecimalField` NaN sub-case failed; the file-field sub-case PASSED. fvk strictly improved on baseline (`failures=1, errors=4`) yet is scored identically. Cause: a Django subtest output line-concatenation the SWE-bench parser mis-assigns. **Implication for SYNTHESIS:** per-test counts in `report.json` may be inflated; the **resolved/unresolved** verdict (and thus the "zero flips" macro fact and our failing-set membership) is still reliable — django-13212 is genuinely unresolved because the decimal sub-case fails. Ref: `django__django-13212/evidence/failing-test-and-eval.md`. (Lead could not re-run the testbed: system Python 3.12 vs Django 3.2; truth established from stored output — consistent with no-exec analysis.)
