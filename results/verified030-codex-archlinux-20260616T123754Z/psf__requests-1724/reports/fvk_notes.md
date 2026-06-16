# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found that the required repair is exactly the
native-string conversion already added in `PreparedRequest.prepare_method()`:

```python
self.method = to_native_string(self.method.upper())
```

## Trace To Findings And Obligations

- F-001 is the reported defect. PO-001 proves the local repair and PO-002 proves
  that the public `requests.request()` path reaches that repair before
  `HTTPAdapter.send()` consumes `request.method`.
- PO-003 confirms the fix preserves uppercasing, so no extra source edit is
  needed to retain existing method value semantics.
- F-002 and PO-004 identify the only side condition: the method text is an ASCII
  HTTP method token. The issue's `u'POST'` example supports that domain, so this
  is not a source-code bug to repair.
- F-003 identifies a public test gap. The task forbids editing tests, so no test
  file was changed.
- PO-005 and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` show that V1 changes no public
  signatures or call shapes.

## Alternatives Considered

- I did not change `Session.request()` or `Session.prepare_request()`: PO-002
  shows their repeated `.upper()` calls are harmless for ASCII method tokens and
  preserving them avoids broadening the public behavior change.
- I did not add adapter-level normalization: F-001 localizes the defect to
  prepared request construction, and PO-001 discharges that boundary.
- I did not expand support to non-ASCII method text: F-002 records that the
  public issue does not require it.

No tests, Python, `kompile`, or `kprove` were run.
