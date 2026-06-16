# Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Target

Prove the targeted merge contract for `requests.sessions.merge_setting()` in
the mapping/mapping case used by `Session.prepare_request()` for headers:

`result = filter_none(overlay(session_setting, request_setting))`

where `overlay` copies session values first and request values second, and
`filter_none` removes keys whose final merged value is `None`.

## Constructed Proof Sketch

P1. In the mapping/mapping branch, both early returns are skipped because
neither setting is Python-level `None`, and both inputs satisfy `Mapping`.

P2. `merged_setting = dict_class(to_key_val_list(session_setting))` creates the
base mapping from the session setting. `merged_setting.update(...)` overlays
request values on that base, so request keys win on conflict. This discharges
PO-2.

P3. V1 computes `none_keys` from `merged_setting.items()`, not from
`request_setting.items()`. Therefore every key whose final value is `None` is
selected, including a key that came only from `Session.headers`. Deleting those
keys yields `filter_none(overlay(session, request))`. This discharges PO-1 and
PO-3.

P4. If the session has `accept-encoding -> None` and the request has
`accept-encoding -> "identity"`, the overlay's final value is `"identity"`, so
the key is not in `none_keys` and remains present. This discharges PO-4.

P5. If the session has `foo -> "bar"` and the request has the same header key
with value `None`, `CaseInsensitiveDict` makes the conflict case-insensitive.
The overlay's final value is `None`, so the key is deleted. This discharges
PO-5.

P6. The deletion loop operates on `merged_setting`, which was freshly created
from `dict_class(...)`. It does not delete from `session_setting` or
`request_setting`. This discharges PO-6.

P7. The non-mapping and Python-level absent-setting branches are textually
unchanged by V1. This discharges PO-7.

P8. `Request.__init__` normalizes missing request headers to `{}`. Therefore the
reported use case, where the user supplies no per-request headers, reaches the
mapping/mapping branch with an empty request mapping. This discharges PO-8.

## Adequacy Gate

`FORMAL_SPEC_ENGLISH.md` matches `INTENT_SPEC.md` for all required behavior:
session-level header `None` deletion, request-level `None` deletion,
request-over-session precedence, case-insensitive header matching, no mutation
of session headers, and non-mapping frame behavior. `SPEC_AUDIT.md` records one
non-blocking ambiguity for a direct helper call outside the public issue path;
that ambiguity does not justify a V2 source edit.

## Test Redundancy

No tests were modified. If the K proof is machine-checked later, unit tests that
only assert request-level or session-level header `None` deletion for in-domain
mapping inputs would be subsumed by C-REQUEST-NONE and C-SESSION-NONE. This is a
recommendation only; tests should be kept until the emitted commands return
`#Top`.

## Commands To Machine-Check Later

Run from `fvk/`:

```sh
kompile mini-requests-merge.k --backend haskell
kast --backend haskell requests-merge-spec.k
kprove requests-merge-spec.k
```

Expected result after a successful machine check: `#Top`.

## Residual Risk

- The proof is constructed, not machine-checked.
- The K fragment models canonical header keys rather than the full
  `CaseInsensitiveDict` implementation.
- The full Requests request lifecycle, network sending, adapters, cookies,
  authentication, and redirects are not formally modeled.
- Termination is not separately proved; the audited code path consists of
  finite mapping/list operations.

