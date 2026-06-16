# FVK Findings

Status: constructed, not machine-checked. No tests or project code were run.

## F-01: Legacy substring rewrite corrupts parametrized ids

Classification: code bug fixed by V1.

Evidence: SPEC ledger E-01, E-03, E-06.

Input: a collected parametrized function whose selected modpath part is `test_boo[..[]`.

Observed before V1: `getmodpath()` assembled `test_boo[..[]`, then applied `.replace(".[", "[")`, producing `test_boo[.[]`.

Expected: `test_boo[..[]`, with all characters from the parametrized id preserved.

Proof obligations: O-01, O-03, O-05.

Resolution: V1 removes the post-join replacement and returns the assembled string unchanged. No further code change is needed.

## F-02: Old generated-yield-test formatting is obsolete, not a preserved requirement

Classification: compatibility question resolved by public intent.

Evidence: SPEC ledger E-04, E-05, E-08.

Input: the historical shape `test_gen` parent with a generated child named `[0]`.

Observed with V1: a literal node-name part `[0]` would remain a separate joined part, producing `test_gen.[0]` if such a chain were represented as normal node parts.

Historical behavior: the legacy replacement displayed `test_gen[0]`.

Expected for this checkout: no generated-yield child formatting obligation is in scope, because yield tests have been removed/ignored since pytest 4.0.

Proof obligations: O-04.

Resolution: keep V1 unchanged. Reintroducing a special case for `[0]` would be implementation-derived and would preserve an obsolete behavior at the cost of the public bug fix.

## F-03: No remaining headline contributor rewrites the domain string

Classification: no code bug found after propagation audit.

Evidence: SPEC ledger E-02, E-07.

Input: `getmodpath()` returns `test_boo[..[]`.

Observed in source: `reportinfo()` returns it as the third tuple element, `Node.location` converts it with `str(...)`, and `TestReport.head_line` returns that value.

Expected: the failure headline uses the exact modpath returned by `getmodpath()`.

Proof obligations: O-03.

Resolution: no edits are needed in `reports.py`, `nodes.py`, or `terminal.py`.

## F-04: Proof is constructed but not machine-checked

Classification: proof capability gap, not a source-code bug.

Evidence: FVK method and the task's no-execution rule.

Input: the K-style claims in `PROOF_OBLIGATIONS.md`.

Observed: commands cannot be run in this session.

Expected: artifacts record exact commands and expected outcome, labeled constructed-not-machine-checked.

Proof obligations: O-06.

Resolution: do not delete or modify tests based on this proof. Keep the V1 code decision because it is justified by public intent and source reasoning, not by an unavailable execution result.

## F-05: Test coverage recommendation only

Classification: test gap recommendation.

Evidence: F-01 and O-03.

Recommended future test: a failure-report/headline assertion for a parametrized id containing `".["`, such as `pytest.mark.parametrize("a", ["..["])`.

Expected assertion: the long failure headline contains `test_boo[..[]`, not `test_boo[.[]`.

Resolution: no test files were edited because the task forbids modifying tests.
