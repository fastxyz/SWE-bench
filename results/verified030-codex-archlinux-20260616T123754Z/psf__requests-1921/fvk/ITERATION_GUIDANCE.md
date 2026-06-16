# Iteration Guidance

Status: V1 stands; no V2 source edit is recommended by this FVK pass.

## Decision

Keep the V1 source change in `repo/requests/sessions.py` unchanged. Findings
FVK-F1 and FVK-F2 are resolved by deleting final `None` values from the merged
mapping. Proof obligations PO-1 through PO-8 are discharged by the current V1
control flow and by the constructed K claims.

## Do Not Change

- Do not mutate `Session.headers` during request preparation. The sentinel value
  can remain in the session defaults and continue to suppress the header.
- Do not move the filter into `PreparedRequest.prepare_headers()`; the public
  issue localizes the bug to merge behavior before firing off the request.
- Do not change `CaseInsensitiveDict`; the existing header merge path already
  gets case-insensitive behavior through `dict_class=CaseInsensitiveDict`.

## Possible Future Work

- Add public tests for `session.headers['Accept-Encoding'] = None` and for a
  request-level non-`None` override of a session-level `None`, if tests are
  allowed in a normal development setting.
- Clarify whether direct internal calls of `merge_setting(None,
  session_mapping_with_None)` should also filter session-side `None` values.
  This is outside the issue path because `Request.__init__` normalizes missing
  headers to `{}`.
- Machine-check the FVK artifacts with the commands in `PROOF.md` when a K
  environment is available.

