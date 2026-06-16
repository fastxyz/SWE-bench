# FVK Findings

Status: constructed, not machine-checked.

## F-001: Pre-fix child argv omitted CPython `-X` options

- Classification: code bug, resolved by V1.
- Evidence: E1-E4.
- Input: parent process has `_xoptions` containing UTF-8 mode and runs
  `manage.py runserver` with autoreload.
- Observed before V1: child argv replayed `sys.executable`, warning options,
  script path, and user args, but no `-X` option. The issue shows this as
  `UTF-8` in the parent and `cp936` in the reloader child.
- Expected: child argv must contain an equivalent `-X utf8` interpreter option
  before `manage.py` so UTF-8 mode remains active.
- V1 status: discharged by PO-001, PO-002, and PO-004.

## F-002: `-X` options with values must preserve their values

- Classification: completeness obligation, discharged by V1.
- Evidence: E1 and E4 refer to `-X` options generally and to `sys._xoptions`,
  whose entries may be flag-like or value-like.
- Input: `_xoptions` contains an option such as `name=value`.
- Observed risk if only keys were replayed: child argv would lose the explicit
  value.
- Expected: value-style xoptions are replayed as `-Xname=value`.
- V1 status: discharged by PO-002.

## F-003: Attached `-X<key>` spelling is a representation assumption

- Classification: named default-domain assumption, non-blocking.
- Evidence: issue shows `-X utf8`; V1 emits an attached short-option form such
  as `-Xutf8`.
- Expected: the child process receives a CPython-equivalent interpreter option.
- V1 status: accepted by SPEC_AUDIT C4 as a default-domain assumption. This is
  not a source-code defect unless CPython rejects attached `-X` arguments, which
  this run did not execute or machine-check.

## F-004: Direct `.exe` fallback does not replay interpreter flags

- Classification: out-of-scope branch for this issue, non-blocking.
- Evidence: E2 reproduces with `python -X ... manage.py`; source/public tests
  show the `.exe` fallback intentionally bypasses `sys.executable`.
- Input: `sys.argv[0]` is missing but a corresponding `.exe` shim exists.
- Observed: argv is the shim path plus user args.
- Expected for this branch: preserve existing behavior; no Python interpreter is
  being invoked to receive `-W` or `-X` flags.
- V1 status: discharged by PO-007.

## F-005: Proof is constructed, not machine-checked

- Classification: proof-honesty caveat, not a code bug.
- Evidence: FVK docs require `kompile`/`kprove` commands but this benchmark
  forbids running K tooling.
- Expected: keep tests; treat proof and test-redundancy as conditional until
  `kprove` returns `#Top`.
- V1 status: recorded in PROOF.md and ITERATION_GUIDANCE.md.
