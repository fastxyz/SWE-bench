# Public Compatibility Audit

Status: constructed from public source inspection, not machine-checked.

## Changed Symbol

- `requests.sessions.merge_setting(request_setting, session_setting,
  dict_class=OrderedDict)`

## Compatibility Results

- Signature: unchanged.
- Return type shape for mapping/mapping settings: unchanged `dict_class`
  mapping, with additional removal of final `None` values.
- Return behavior for non-mapping settings: unchanged.
- Return behavior for `session_setting is None`: unchanged.
- Return behavior for `request_setting is None`: unchanged.
- Mutation behavior: `session_setting` and `request_setting` are not mutated in
  the mapping/mapping branch; deletion is applied to the merged copy.

## Public Call Sites Reviewed

- `merge_hooks()` delegates hook merging to `merge_setting()` only after its
  special empty-list rules.
- `Session.prepare_request()` uses `merge_setting()` for headers, params, auth,
  cookies are handled separately, and hooks use `merge_hooks()`.
- `Session.request()` uses `merge_setting()` for proxies, stream, verify, and
  cert after environment-derived values are gathered.

## Compatibility Assessment

The V1 change broadens the existing `None` deletion rule from request-side
mapping values to final merged mapping values. This affects mapping settings
only and is consistent with the helper's existing comment, the public header
intent, and the existing request-level removal behavior. No public override,
signature, or callsite incompatibility was found.

