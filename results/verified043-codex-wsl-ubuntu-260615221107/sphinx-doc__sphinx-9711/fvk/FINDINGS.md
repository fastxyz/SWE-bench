# Findings

Status: constructed, not machine-checked.

## F-001: V1 fixes the reported version-ordering bug

- Classification: confirmed code fix.
- Input: `needs_extensions = {'sphinx_gallery.gen_gallery': '0.6.0'}` and loaded
  extension metadata version `0.10.0`.
- Pre-fix observed behavior from the issue: Sphinx raises a "not new enough"
  `VersionRequirementError`.
- Expected behavior from public intent: `0.10.0` is newer than `0.6.0`, so the
  entry must satisfy the requirement.
- V1 audit result: `_is_version_requirement_satisfied()` uses
  `Version('0.10.0') >= Version('0.6.0')`, so the entry does not raise.
- Proof obligations: PO-001, PO-002, PO-007.
- Code action: no further code change needed.

## F-002: Non-PEP-440 fallback is compatibility behavior, not semantic proof

- Classification: residual compatibility boundary.
- Input: a required or loaded extension version string that `packaging.version`
  rejects.
- Observed V1 behavior: helper falls back to lexicographic `loaded >= required`.
- Expected behavior from public intent: underspecified outside documented version
  strings; public docs say the metadata value is a string and the configuration
  documentation describes `major.minor` version strings.
- V1 audit result: acceptable as a minimal-change compatibility fallback, but it
  must not be cited as proof of correct version semantics outside the documented
  version-string domain.
- Proof obligations: PO-003.
- Code action: keep V1 unchanged.

## F-003: No public compatibility break found

- Classification: compatibility confirmation.
- Input: public users of `verify_needs_extensions`, extension metadata
  producers, and Sphinx extension setup metadata.
- Observed V1 behavior: function signature and metadata storage remain
  unchanged; `packaging` is already a project dependency.
- Expected behavior from public intent: minimal targeted fix without unrelated
  API changes.
- V1 audit result: no compatibility blocker.
- Proof obligations: PO-008.
- Code action: keep V1 unchanged.

## F-004: Proof is constructed only

- Classification: proof status and test guidance.
- Input: the FVK proof artifacts and K commands.
- Observed V1/FVK behavior: no `kompile`, `kast`, `kprove`, Python, or test
  commands were run.
- Expected behavior from user and FVK honesty gate: write commands into the
  artifacts and reason about expected outcomes only.
- V1 audit result: proof can justify source changes by reasoning, but test
  removal or machine-verified claims must wait for an actual K/toolchain run in
  an environment that supports it.
- Proof obligations: PO-009.
- Code action: no test files touched and no tests recommended for deletion.
