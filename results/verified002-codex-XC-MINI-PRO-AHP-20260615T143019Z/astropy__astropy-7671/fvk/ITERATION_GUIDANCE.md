# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

V1 stands unchanged. The FVK audit found that the V1 helper discharges the
reported mixed int/string `LooseVersion` failure for the intent-derived domain
of numeric package version strings with optional suffixes.

Trace:

- `fvk/FINDINGS.md` F1 confirms the original TypeError path is removed.
- `fvk/FINDINGS.md` F2 confirms public API compatibility is preserved.
- `fvk/PROOF_OBLIGATIONS.md` PO1-PO5 are satisfied by the V1 source.
- `fvk/FINDINGS.md` F3 records the only residual boundary and does not justify a
  source change for this task.

## Suggested Follow-Up Tests

Do not edit tests in this benchmark. In a normal development setting, add or
keep tests for:

- `minversion(module_with_version_1_14_3, "1.14dev") is True`;
- `minversion(module_with_version_0_12_2, "0.12.0.dev") is True`;
- missing import by string returns `False`;
- invalid module argument raises `ValueError`.

Only after running the emitted K commands and getting `#Top` should any
in-domain point tests be considered redundant, and even then test removal should
be conservative because the proof uses a mini semantics.

## Future Spec Expansion

If Astropy wants full PEP 440 semantics, replace the issue-derived numeric
prefix contract with an explicit package-version parser contract. That would be
a new requirement because the public issue asks for a regex guard around
`LooseVersion`, not a dependency or parser replacement.

