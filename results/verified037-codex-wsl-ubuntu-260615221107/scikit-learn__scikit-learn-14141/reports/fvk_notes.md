# FVK Notes

## Decision summary

V1 stands unchanged as the source fix. The FVK audit confirmed that the public
intent is satisfied by adding `"joblib"` to `_get_deps_info()`'s static
dependency list, and it did not identify a justified additional source edit.

## Traceability

- Kept `repo/sklearn/utils/_show_versions.py` unchanged after V1.
  - Findings: F1 localizes the pre-V1 bug to the missing static dependency-list
    member; F2 confirms that V1 applies the existing dependency loop to
    `joblib`.
  - Proof obligations: OBL-1 requires a `joblib` key in dependency info; OBL-2
    requires generic version-or-None semantics; OBL-3 requires propagation into
    `show_versions()` output. V1 discharges all three without more source code.
- Did not edit `repo/ISSUE_TEMPLATE.md`.
  - Findings: F3 records that the template already asks scikit-learn `>= 0.20`
    users to call `sklearn.show_versions()`.
  - Proof obligations: OBL-4 states that the issue-template alternative is
    discharged once `show_versions()` itself reports `joblib`.
- Did not add a special-case `joblib` import path.
  - Findings: F2 confirms that the current generic dependency loop is enough.
  - Proof obligations: OBL-2 specifically requires `joblib` to use the same
    import/version-or-None behavior as the other dependency entries.
- Did not modify tests.
  - Findings: F5 records that the proof is constructed but not machine-checked.
  - Proof obligations: OBL-6 keeps any proof-based test removal conditioned on
    future K execution, and the benchmark forbids test-file edits.
- Added FVK artifacts under `fvk/`.
  - Findings: F5 records the honesty caveat.
  - Proof obligations: OBL-6 requires exact commands and the
    constructed-not-machine-checked status. The required five artifacts are
    `SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`, `PROOF.md`, and
    `ITERATION_GUIDANCE.md`; the extra adequacy and `.k` files satisfy the FVK
    documentation's formal-core and adequacy-gate requirements.

## Alternative interpretations considered

- Adding `joblib` only to the issue template was rejected because F3/OBL-4 show
  that the template already routes affected users to `show_versions()`, while
  F1/OBL-1 identify `show_versions()` as the incomplete observable.
- Treating `joblib` as optional or external to the dependency list was rejected
  because public evidence E4 in the ledger shows `joblib` in `install_requires`,
  and OBL-2 covers it as a normal dependency.
- Adding an ordering assertion for the printed row was rejected because no
  public evidence requires a specific order; OBL-5 preserves inclusion and
  compatibility without inventing an unsupported ordering condition.

## Verification status

No tests, Python code, or K tooling were executed. The commands to run later are
recorded in `fvk/PROOF_OBLIGATIONS.md` and `fvk/PROOF.md`.
