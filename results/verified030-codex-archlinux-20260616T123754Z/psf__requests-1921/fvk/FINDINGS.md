# Findings

Status: constructed, not machine-checked. Findings are based on public intent
and source inspection only; no tests, Python, or K tooling were run.

## FVK-F1 - Resolved code bug: session default header `None`

- Classification: code bug fixed by V1.
- Input: `Session.headers` contains canonical `accept-encoding -> None`, and
  the request supplies no `Accept-Encoding` override.
- Pre-fix observed behavior: the merged prepared headers retained the key with
  value `None`, yielding the reported `Accept-Encoding: None` header.
- Expected behavior: the prepared request omits `Accept-Encoding`.
- V1 status: resolved. `merge_setting()` now builds the merged mapping, records
  every key whose final merged value is `None`, and deletes those keys from the
  merged copy.
- Trace: PO-1, PO-3, PO-8; claims C-MERGE-MAPPING and C-SESSION-NONE.

## FVK-F2 - Confirmed frame: request-level `None` deletion remains intact

- Classification: confirmed compatibility.
- Input: session has `foo -> "bar"` and request has `FOO -> None` in the header
  path.
- Expected behavior: prepared headers omit `foo`.
- V1 status: confirmed by the same final-value deletion rule. Because
  `Session.prepare_request()` uses `CaseInsensitiveDict`, the case-insensitive
  key is updated to `None` and then removed.
- Trace: PO-5; claim C-REQUEST-NONE.

## FVK-F3 - Non-blocking ambiguity: direct helper call with absent request setting

- Classification: underspecified intent, not a code bug for this issue.
- Input: a direct internal call `merge_setting(None, session_mapping)` where
  `session_mapping` contains a key whose value is `None`.
- Current behavior: the helper returns `session_mapping` through the existing
  early return without filtering it.
- Expected behavior from public issue: unspecified for this direct helper edge.
  The issue path uses `Request.__init__`, which converts missing headers into
  `{}`, so session default headers reach the mapping/mapping branch covered by
  V1.
- V1 status: no source edit. Broadening this early return would be an additional
  behavior change not required by the public issue.
- Trace: SPEC_AUDIT ambiguous row; PO-8.

## FVK-F4 - Honesty gate: proof constructed only

- Classification: proof capability / environment constraint.
- Input: all claims in `requests-merge-spec.k`.
- Current status: constructed proof only. The task forbids running `kompile`,
  `kprove`, Python, or tests.
- Expected later machine-check behavior: `kprove requests-merge-spec.k` should
  return `#Top` after compiling the mini semantics, if the K fragment is
  accepted.
- V1 status: no source edit. The finding gates proof confidence and test
  removal, not the source change itself.
- Trace: PO-9 and `PROOF.md` run commands.

