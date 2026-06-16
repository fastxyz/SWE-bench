# FVK Specification

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 fix for
`repo/django/core/management/commands/loaddata.py`, specifically
`Command.fixture_dirs`.

The observable behavior under audit is the validation of configured fixture
directories before `loaddata` builds its fixture search list.

## Public intent ledger

The full ledger is in `PUBLIC_EVIDENCE_LEDGER.md`. The critical obligations
are:

- E1/E2: The issue requires duplicate detection when `FIXTURE_DIRS` contains
  `Path` instances.
- E5/E6: Duplicate configured fixture directories must raise
  `ImproperlyConfigured("settings.FIXTURE_DIRS contains duplicates.")` to avoid
  repeated fixture loading.
- E5/E7: A configured app default fixture directory is also forbidden to avoid
  repeated fixture loading.
- E8: A nonduplicate `Path` entry in `FIXTURE_DIRS` remains valid.

## Contract

For a finite configured-directory sequence `entries` and finite app default
fixture directory sequence `app_dirs`:

1. Convert each configured entry with `os.fspath()` before duplicate checks.
2. If the converted configured string list has a repeated string, raise the
   existing duplicate `ImproperlyConfigured` error.
3. Otherwise, if an app default fixture directory string equals a converted
   configured directory string, raise the existing default-directory
   `ImproperlyConfigured` error.
4. Otherwise, accept the configured entries and continue building the fixture
   search list, preserving the existing search-order behavior.

## Provenance labels

- PO-001 and PO-002 are intent-derived from E1, E2, E5, and E6.
- PO-003 is intent-derived from E5 and E7.
- PO-004 is intent-derived from E8.
- The exact ordering of duplicate validation before default-directory
  validation is implementation-derived and preserved for compatibility; no
  correctness conclusion depends on a public winner rule for configurations
  that violate both conditions.

## Non-goals and ambiguity

The proof does not cover path aliases whose `os.fspath()` values differ but
whose `os.path.realpath()` values later collapse to the same directory. That
possible hardening is Finding F-002. The available issue text is specific to
`Path` instances and does not clearly authorize broadening validation semantics
to all canonical filesystem aliases in this repair.
