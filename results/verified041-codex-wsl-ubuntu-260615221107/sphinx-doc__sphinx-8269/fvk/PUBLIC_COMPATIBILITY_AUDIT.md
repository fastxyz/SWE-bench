# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Public Symbols

None. V1 changes only the body of `CheckExternalLinksBuilder.check_thread.<locals>.check_uri()` by inserting `response.raise_for_status()` in an existing branch.

## API And Callsite Review

- Configuration names are unchanged: `linkcheck_anchors`, `linkcheck_anchors_ignore`, `linkcheck_ignore`, `linkcheck_auth`, `linkcheck_request_headers`, `linkcheck_retries`, `linkcheck_timeout`, and `linkcheck_workers` are unaffected.
- Builder name and output formats are unchanged: `linkcheck`, `output.txt`, and `output.json` keep the same producer code.
- No method signature changed.
- No subclass or virtual dispatch call changed.
- The new call uses an existing `requests.Response` method already used twice in the same function for non-anchor checks.

## Verdict

Pass. No public compatibility problem was found, and no production-code change beyond V1 is justified by compatibility concerns.
