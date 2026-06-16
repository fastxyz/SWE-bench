# Public Evidence Ledger

E-001

- Source: `benchmark/PROBLEM.md`
- Evidence: "`needs_extensions` checks versions using strings" and treats
  versions in a "string-like" manner.
- Obligation: do not compare documented versions lexicographically.
- Status: encoded in `SPEC.md`, `PROOF_OBLIGATIONS.md`, and
  `needs-extensions-spec.k`.

E-002

- Source: `benchmark/PROBLEM.md`
- Evidence: "`sphinx-gallery 0.10.0 should be accepted if 0.6 is the minimum
  specified.`"
- Obligation: loaded `0.10.0` satisfies required `0.6.0` or `0.6`.
- Status: encoded as the concrete witness obligation PO-002.

E-003

- Source: `repo/doc/usage/configuration.rst`
- Evidence: `needs_extensions` is a dictionary of extension version
  requirements, and version strings should be in the form `major.minor`.
- Obligation: the in-domain contract is over version strings, not arbitrary
  Python objects.
- Status: domain for PO-001 and PO-007.

E-004

- Source: `repo/doc/extdev/index.rst`
- Evidence: extension metadata key `'version'` is "a string that identifies the
  extension version" and is used for `needs_extensions`; if omitted,
  `"unknown version"` is substituted.
- Obligation: known metadata versions are strings; `unknown version` remains a
  special too-weak value.
- Status: PO-001, PO-005, and PO-007.

E-005

- Source: original benchmark task
- Evidence: "Keep the change minimal and targeted: fix the described issue
  without unrelated refactoring."
- Obligation: preserve branches not implicated by the version-ordering defect.
- Status: PO-003 through PO-008.

E-006

- Source: `repo/setup.py`
- Evidence: `packaging` is listed in `install_requires`.
- Obligation: using `packaging.version.Version` does not introduce a new
  dependency.
- Status: PO-008.

E-007

- Source: `repo/sphinx/extension.py`
- Evidence: V1 implements `_is_version_requirement_satisfied()` using
  `Version(loaded) >= Version(required)` and falls back to `loaded >= required`
  on `InvalidVersion`.
- Obligation: implementation fact to prove against the intent-derived
  obligations; not an independent source of expected behavior.
- Status: modeled in `mini-sphinx-version.k` and audited in `PROOF.md`.
