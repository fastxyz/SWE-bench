# FVK Notes

## Method

I used the FVK intent-first flow from the required docs: public issue and
docstring evidence first, current V1 implementation second, then proof
obligations and findings. No tests, Python, or K tooling were run.

## Source Decisions

1. Kept the V1 `multi_class` branch fix.
   - Finding: `fvk/FINDINGS.md` F-001.
   - Proof obligations: `fvk/PROOF_OBLIGATIONS.md` O-001 and O-002.
   - Reason: the issue's failing path is `multi_class='auto'`, but the
     coefficient-path shape follows the resolved local `multi_class`. Using
     `self.multi_class` would still treat resolved OvR paths as multinomial
     whenever the constructor value remains `'auto'`.

2. Kept the V1 non-elastic-net `l1_ratio_` guard.
   - Finding: `fvk/FINDINGS.md` F-003.
   - Proof obligation: `fvk/PROOF_OBLIGATIONS.md` O-004.
   - Reason: the reported reproducer uses the default non-elastic-net penalty.
     Once the indexing bug is fixed, the same no-refit block must not attempt
     to average `[None]`; the documented absence marker is `None`.

3. Kept the V1 `np.asarray(l1_ratios_)` conversion for elastic-net averaging.
   - Finding: `fvk/FINDINGS.md` F-005.
   - Proof obligation: O-004.
   - Reason: the public docstring accepts list-like `l1_ratios`; fold winner
     indices are NumPy-array-shaped. Converting at selection preserves list and
     array inputs without changing the public API.

4. Added the V2 final reshape guard change.
   - Finding: `fvk/FINDINGS.md` F-002.
   - Proof obligation: `fvk/PROOF_OBLIGATIONS.md` O-005.
   - Reason: FVK found that V1 still used `self.l1_ratios is not None` when
     deciding whether to add the l1-ratio dimension to `coefs_paths_`,
     `scores_`, and `n_iter_`. That conflicts with the docstring obligation
     that `l1_ratios` is only used for `penalty='elasticnet'`. V2 now uses
     `self.penalty == 'elasticnet'`, matching the active parameter semantics.

5. Left public signatures and constructor parameter storage unchanged.
   - Finding: no unresolved compatibility finding.
   - Proof obligation: O-006.
   - Reason: the compatibility audit found no need to change signatures,
     return types, or stored constructor inputs. Mutating `self.multi_class` or
     `self.l1_ratios` would be a broader public estimator behavior change.

## Artifacts

The required FVK artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also added the formal/audit support files required by the FVK docs:

- `fvk/mini-logregcv.k`
- `fvk/logregcv-refit-false-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

## Verification Status

The proof is constructed, not machine-checked. The commands to run later are
listed in `fvk/PROOF.md`, but this environment forbids executing them. No test
files were modified.
