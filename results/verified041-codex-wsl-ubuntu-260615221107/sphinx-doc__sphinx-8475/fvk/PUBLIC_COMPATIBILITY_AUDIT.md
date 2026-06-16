# Public Compatibility Audit

Changed production symbol: `sphinx.builders.linkcheck.CheckExternalLinksBuilder`
internal request exception handling in `check_thread().check_uri()`.

## Compatibility Checks

- Public builder name `linkcheck`: unchanged.
- Config values such as `linkcheck_retries`, `linkcheck_timeout`,
  `linkcheck_anchors`, `linkcheck_auth`, and `linkcheck_request_headers`:
  unchanged.
- Public output files `output.txt` and `output.json`: schema and formatting
  paths unchanged; V1 changes only which request path is tried before producing
  the existing status categories.
- Method/function signatures: unchanged.
- Subclass/override compatibility: no virtual method signature or dispatch shape
  changed.
- Tests: no test files modified.

Verdict: compatible. No public callsite, override, producer/consumer shape, or
storage format requires a follow-up source change.
