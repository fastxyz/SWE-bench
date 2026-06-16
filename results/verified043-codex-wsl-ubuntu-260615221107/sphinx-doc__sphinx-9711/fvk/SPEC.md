# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited production code is `repo/sphinx/extension.py`, specifically V1's
new helper `_is_version_requirement_satisfied()` and its use inside
`verify_needs_extensions()`. The goal is to validate the real issue
`sphinx-doc__sphinx-9711`: `needs_extensions` must compare minimum extension
versions as versions, so `0.10.0` is accepted for a `0.6.0` minimum.

## Intent Domain

The proven domain is documented extension version strings. Public documentation
states that `needs_extensions` maps extension names to version strings and that
extension metadata key `version` is a string. Within this domain, the required
ordering is parsed version ordering. Non-PEP-440 strings are outside the
semantic proof domain and are covered only by the compatibility fallback.

## Public Intent Ledger

The detailed ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E-001: the issue says `needs_extensions` compares versions string-like.
- E-002: `0.10.0` must satisfy a `0.6.0` minimum.
- E-003: `needs_extensions` values are documented version strings.
- E-004: extension metadata `version` is a string; absent values become
  `unknown version`.
- E-005: the benchmark requested a minimal targeted fix.
- E-006: `packaging` is already an install requirement.

## Formal Model

The constructed K model is in:

- `fvk/mini-sphinx-version.k`
- `fvk/needs-extensions-spec.k`

The model abstracts `packaging.version.Version` as `validVersion(S)` plus
`versionGE(LOADED, REQUIRED)`, with the intended meaning that both are supplied
by the packaging parser. It keeps `stringGE` only for the compatibility fallback
when a string is not valid in that parser. The model includes finite
requirements, finite loaded extensions, warning for missing extensions,
raising for `unknown version`, raising for known too-old versions, and
continuing for known sufficiently-new versions.

## Function Contracts

`_is_version_requirement_satisfied(required, loaded)`

- Precondition for the semantic version-ordering claim: `required` and
  `loaded` are valid documented version strings.
- Postcondition on that domain: returns true iff `Version(loaded) >=
  Version(required)`.
- Compatibility postcondition outside that domain: if parsing either string
  raises `InvalidVersion`, returns the old string comparison `loaded >=
  required`.

`verify_needs_extensions(app, config)`

- If `config.needs_extensions is None`, return without checks.
- For each configured requirement:
  - missing extension: warn and continue;
  - loaded extension with `unknown version`: raise `VersionRequirementError`;
  - loaded known valid version older than the requirement: raise
    `VersionRequirementError`;
  - loaded known valid version equal to or newer than the requirement: continue.
- Over a finite `needs_extensions` mapping, if all entries are missing or
  sufficiently new and no entry is unknown or too old, the function completes
  without `VersionRequirementError`.

## Adequacy Summary

The adequacy files are:

- `fvk/INTENT_SPEC.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

Every formal claim is traced to public intent or to the minimal-change frame.
The concrete issue witness is not derived from V1 behavior; it comes directly
from the issue statement.

## Machine-Check Commands

These commands were not run in this environment:

```sh
kompile fvk/mini-sphinx-version.k --backend haskell
kast --backend haskell fvk/needs-extensions-spec.k
kprove fvk/needs-extensions-spec.k
```
