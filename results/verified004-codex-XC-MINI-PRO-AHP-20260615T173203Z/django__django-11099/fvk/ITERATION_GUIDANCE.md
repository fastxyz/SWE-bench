# Iteration Guidance

## Decision

Keep V1 source unchanged.

Reason: F-001 identifies the pre-V1 bug and shows V1 resolves it; F-002 reports no remaining intent divergence in the audited validator language; F-003 reports no public compatibility problem; PF-002 reports no proof obstacle requiring another source edit.

## Code Guidance

No additional production-code change is justified by this FVK pass.

Do not move the fix into `RegexValidator`: PO-006 and compatibility audit C-003 identify `RegexValidator` as a broad shared base class, while E-004 scopes the issue to the two auth username validators.

Do not change flags, messages, class names, or migrations: PO-004, PO-005, and PO-006 require preserving those surfaces.

## Test Guidance

No test files may be modified in this benchmark. In a normal development branch, add focused tests for:

- `UnicodeUsernameValidator()("valid\n")` raises `ValidationError`;
- `ASCIIUsernameValidator()("valid\n")` raises `ValidationError`;
- existing valid ASCII and Unicode examples remain valid.

Do not remove tests based on this constructed proof until the recorded `kompile` and `kprove` commands machine-check successfully.

## Formal Guidance

The proof artifacts are sufficient for this narrow issue. A future stronger proof could replace `mini-python-regex.k` with a full Python regular-expression semantics, but that is not needed to justify the current source decision because the abstraction preserves the exact property under audit.
