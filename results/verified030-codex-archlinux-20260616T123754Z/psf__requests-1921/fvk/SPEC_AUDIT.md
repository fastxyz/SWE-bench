# Spec Audit

Status: adequacy gate for the constructed K claims.

| Formal item | Intent item | Audit | Rationale |
| --- | --- | --- | --- |
| C-MERGE-MAPPING | E1, E2, E4, E6 | Pass | It states the merge-before-send behavior directly and applies deletion to final merged values, which is the issue's missing case. |
| C-SESSION-NONE | E2, E3, E8 | Pass | It covers the reported `session.headers['Accept-Encoding'] = None` path with no request override. |
| C-REQUEST-NONE | E1, E5, E7 | Pass | It preserves the documented and public-test-supported request-level deletion behavior, including case-insensitive header matching. |
| C-REQUEST-OVERRIDE | E6 plus default override convention | Pass | Request settings are the explicit per-request inputs and already override session mappings in `merge_setting()`. Deletion after overlay keeps a non-`None` request override. |
| C-NONMAPPING-FRAME | E6 | Pass | It preserves the helper's documented bypass for non-dictionary settings. |
| Canonical-key abstraction | E7 | Pass | The abstraction keeps the property under test: presence or absence of a header key after case-insensitive matching. |
| Direct helper call `merge_setting(None, session_mapping_with_None)` | No public issue-path evidence | Ambiguous, non-blocking | The code preserves the existing early return. The public issue path uses `Request.__init__`, which turns missing headers into `{}`, so this case does not justify a V2 source edit. |

No formal-English claim contradicts `INTENT_SPEC.md`. The only ambiguity is a
direct helper edge outside the public issue path and outside the V1 change's
necessary behavioral surface.

