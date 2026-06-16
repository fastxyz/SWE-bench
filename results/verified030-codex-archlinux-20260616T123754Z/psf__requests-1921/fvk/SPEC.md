# FVK Spec

Status: constructed, not machine-checked.

## Scope

The formal target is `requests.sessions.merge_setting()` for the mapping merge
case used by `Session.prepare_request()` to build prepared headers. The modeled
observable is the final header mapping passed to `PreparedRequest.prepare()`.

This is a targeted FVK audit of the V1 fix, not a formalization of every
function in Requests. Unmodeled behavior is listed as residual risk in
`PROOF.md` and `ITERATION_GUIDANCE.md`.

## Public Intent Ledger

The detailed ledger is in `PUBLIC_EVIDENCE_LEDGER.md`. The core obligations are:

- E1/E5: request-level `None` already means remove the header.
- E2/E3: session-level default header `None` must also remove the header, not
  send `Accept-Encoding: None`.
- E4: the bug is in header merge semantics before firing off the request.
- E6: request settings override session settings, and non-mapping settings keep
  the existing bypass behavior.
- E7: header matching in this path is case-insensitive.
- E8: `Request(headers=None)` becomes `request.headers == {}`, so the reported
  session-default case enters the mapping/mapping merge branch.

## Definitions

For mapping settings, define:

- `overlay(session, request)`: the mapping made by copying `session` into
  `dict_class`, then updating with `request`; request keys win on conflict.
- `filter_none(mapping)`: the mapping made by deleting every key whose final
  value is Python `None`.
- `merge_headers(request, session) = filter_none(overlay(session, request))`.

For header mappings, keys are considered through `CaseInsensitiveDict`, so
`FOO`, `Foo`, and `foo` denote the same header key in the prepared request.

## Contract

For `merge_setting(request_setting, session_setting, dict_class)`:

1. If both settings are mappings accepted by `to_key_val_list()`, the result is
   `dict_class(to_key_val_list(session_setting))`, updated with
   `to_key_val_list(request_setting)`, with all final `None` values removed.

2. In the header call path, the prepared request receives no header whose final
   merged value is `None`.

3. If a session header is `None` and the request supplies no value for that
   header, the header is absent from the prepared request.

4. If a request header is `None`, the header is absent from the prepared
   request even if the session provided a value, preserving the previously
   tested behavior.

5. If the session header is `None` but the request supplies a non-`None` value
   for the same header, the request value is present.

6. Deleting `None` entries happens only on the merged result. `Session.headers`
   is not mutated by request preparation.

7. Existing non-mapping branches are preserved: when either setting is not a
   mapping, `merge_setting()` keeps the pre-existing early-return behavior.

## Formal Artifacts

- `mini-requests-merge.k`: a small K-style semantics for settings represented
  as absent settings, scalar settings, and canonical-key maps.
- `requests-merge-spec.k`: reachability claims for the mapping merge contract,
  session-level header deletion, request-level header deletion, request
  override, and non-mapping frame behavior.

All K artifacts are constructed, not machine-checked. The commands to run later
are listed in `PROOF.md`.

