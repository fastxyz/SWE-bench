# Intent Spec

Status: constructed from public intent only. This file does not treat the V1
implementation as expected behavior.

## Required behavior

I-001. `needs_extensions` is a dictionary from extension names to minimum
extension version strings. For documented version strings, the comparison must
use version ordering, not lexicographic string ordering.

I-002. The reported witness must pass: a loaded extension version `0.10.0`
satisfies a configured minimum `0.6.0`.

I-003. Requirement checks apply only to configured entries in
`needs_extensions`; requirements need not be specified for every loaded
extension.

I-004. If a configured extension is not loaded, the existing public behavior is
to warn and continue. The original task required a minimal targeted fix, so
this non-version-comparison branch must be preserved.

I-005. If a configured extension is loaded but reports `unknown version`, the
existing public behavior is to raise `VersionRequirementError`. The original
task required a minimal targeted fix, so this branch must be preserved.

I-006. For non-PEP-440 or non-documentation-conforming version strings other
than `unknown version`, public intent is underspecified. The compatibility
frame is to avoid introducing a new exception path while fixing documented
version strings.

I-007. No public API shape should change for this fix: `verify_needs_extensions`
must keep its signature and extension metadata storage must keep using the
`version` string supplied by extension `setup()` metadata.
