# Iteration Guidance

Status: V1 stands. No source edits beyond V1 are justified by the FVK audit.

## Decision

Keep V1 unchanged.

Rationale:

* PO1-PO4 discharge the MySQL and Oracle source-timezone obligations.
* PO5-PO6 discharge the SQLite producer/consumer and source-interpretation
  obligations.
* PO7 confirms the fix covers the public conversion-before-extract/truncate
  family, not only the single `__date` example.
* PO8 confirms the public backend operation API remains compatible.
* Findings F-001 through F-003 are resolved by V1.
* F-004 is a proof boundary, not a production-code defect.

## Next tests to add in a normal development environment

Do not modify tests in this task. In a normal Django development pass, add
backend-specific tests for:

* `DATABASES['TIME_ZONE']` equal to current timezone: no MySQL `CONVERT_TZ()`;
* `DATABASES['TIME_ZONE']` different from current timezone: conversion source
  is the database timezone;
* SQLite date/time extract and truncation from a non-UTC database timezone;
* Oracle generated conversion source timezone.

## Machine-checking guidance

The FVK proof is constructed, not machine-checked. In a K-capable environment,
run the commands recorded in `PROOF.md`. Do not remove tests unless those claims
are actually machine-checked and the tests are shown to be strictly in-domain
unit cases subsumed by the proof.
