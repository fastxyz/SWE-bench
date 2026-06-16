# Proof Obligations

Status: constructed, not machine-checked.

PO-001: Valid-version helper contract

- Claim: for valid documented version strings `required` and `loaded`,
  `_is_version_requirement_satisfied(required, loaded)` returns true iff
  `Version(loaded) >= Version(required)`.
- Evidence: E-001, E-003, E-004.
- Discharge: V1 calls `Version(loaded) >= Version(required)` before any fallback.

PO-002: Reported issue witness

- Claim: `required = 0.6.0`, `loaded = 0.10.0` returns true and therefore does
  not raise for that entry.
- Evidence: E-002.
- Discharge: both strings are valid version strings; parsed version ordering has
  `0.10.0 >= 0.6.0`.

PO-003: Invalid-version compatibility fallback

- Claim: if either string raises `InvalidVersion`, helper behavior falls back to
  `loaded >= required`, preserving the old non-version behavior instead of
  introducing a new exception path.
- Evidence: E-005, E-006.
- Discharge: V1 catches `InvalidVersion` and returns `loaded >= required`.

PO-004: Missing extension branch

- Claim: if a configured extension is missing, `verify_needs_extensions()` warns
  and continues.
- Evidence: E-005 and the existing public branch in `extension.py`.
- Discharge: V1 did not alter the `extension is None` branch.

PO-005: Unknown version branch

- Claim: if a loaded extension reports `unknown version`, the verifier raises
  `VersionRequirementError`.
- Evidence: E-004, E-005.
- Discharge: V1 preserves the sentinel check before calling the helper.

PO-006: Too-old valid loaded version branch

- Claim: if loaded and required versions are valid and
  `Version(loaded) < Version(required)`, the verifier raises
  `VersionRequirementError`.
- Evidence: E-001, E-003, E-004.
- Discharge: helper returns false and the existing raise path is taken.

PO-007: Sufficient valid loaded version branch and finite-map lifting

- Claim: if loaded and required versions are valid and
  `Version(loaded) >= Version(required)`, that entry does not raise; by
  induction over finite `needs_extensions` entries, all satisfying entries
  complete without `VersionRequirementError`.
- Evidence: E-001, E-002, E-003, E-004.
- Discharge: helper returns true, the raise condition is false, and the loop
  proceeds to the next entry.

PO-008: Public compatibility

- Claim: no public signature, metadata producer/consumer shape, virtual dispatch
  call, or external dependency set is broken by V1.
- Evidence: E-005, E-006.
- Discharge: `verify_needs_extensions` signature is unchanged; new helper is
  private; `packaging` already exists in `install_requires`.

PO-009: Honesty and execution boundary

- Claim: the FVK result is constructed but not machine-checked; no tests, Python,
  or K commands are used as evidence.
- Evidence: user no-exec instruction and FVK honesty gate.
- Discharge: commands are written in artifacts only and were not executed.
