# Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F-001: Pre-fix hardcoded UTC source violates public intent

Input/scenario: `USE_TZ=True`, database source timezone `Europe/Paris`, current
Django timezone `Europe/Paris`, stored field value `2017-07-06 20:50:00`.

Observed pre-fix behavior from the issue:
`DATE(CONVERT_TZ(field, 'UTC', 'Europe/Paris')) = '2017-07-06'`.

Expected behavior from ledger E2/E3/E5/E6:
`DATE(field) = '2017-07-06'`, because source and target are both
`Europe/Paris`.

V1 status: resolved by PO1-PO3. MySQL now uses `connection.timezone_name` as
source and skips conversion when source equals target.

## F-002: The issue is a family bug, not only a `__date` bug

Input/scenario: any MySQL/SQLite/Oracle datetime cast, extract, or truncation
operation with `USE_TZ=True` and database source timezone different from the
legacy hardcoded UTC assumption.

Observed pre-fix behavior: conversion helpers assumed UTC source for MySQL and
Oracle, and SQLite parsed helper input as UTC.

Expected behavior from ledger E6-E9: conversion before filtering, extracting,
or truncating must start from the database storage timezone.

V1 status: resolved by PO7. V1 applies the same source/target correction to
cast date, cast time, extract, and truncation paths.

## F-003: SQLite private helper protocol must stay internally consistent

Input/scenario: SQLite generated SQL calling datetime helper functions.

Potential observed failure if partially fixed: generated SQL could pass four
arguments while `create_function()` registers a three-argument UDF, or could
pass source/target in an order different from the Python helper.

Expected behavior from PO5: SQL producer and UDF consumer agree on arity and
argument order.

V1 status: resolved. Producer and consumer both use `(source, target)` for
timezone arguments.

## F-004: Proof capability boundary: timezone arithmetic is external

Input/scenario: any value near DST transitions or any backend-specific timezone
table behavior.

Observed limitation: the FVK mini semantics models conversion as
`local(Wall, Source, Target)` and does not prove pytz, MySQL, Oracle, or SQLite
timezone arithmetic.

Expected handling: do not claim machine-checked proof of external timezone
arithmetic. Keep integration tests for actual backends.

V1 status: acceptable boundary, not a code bug. The issue is about selecting the
correct source timezone and skipping no-op conversion; V1 addresses that.

## F-005: No remaining code defect found by this audit

Input/scenario: V1 source-target conversion and no-op behavior for MySQL,
SQLite, and Oracle across cast/extract/trunc paths.

Observed V1 behavior by source inspection: the changed helpers satisfy PO1-PO8.

Expected behavior: match the public intent in `INTENT_SPEC.md`.

V1 status: confirmed. No source edit beyond V1 is justified by the FVK findings.
