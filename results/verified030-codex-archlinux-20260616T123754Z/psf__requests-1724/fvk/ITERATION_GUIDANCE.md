# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

Keep the V1 source change:

```python
self.method = to_native_string(self.method.upper())
```

No additional production-code edit is justified by the FVK findings or proof
obligations.

## Trace

- F-001 is the operative bug. PO-001 and PO-002 show that V1 fixes it at the
  prepared request transport boundary for session-created and manually prepared
  request objects that call `prepare_method()`.
- F-002 is a domain boundary, not a required repair. PO-004 records the ASCII
  method-token precondition needed by `to_native_string()` and supported by the
  public issue.
- F-003 is a test gap. The task forbids editing tests, so the guidance is to add
  a future public regression test outside this benchmark pass.
- PO-005 confirms compatibility: V1 changes no public signatures or call shapes.

## Rejected Follow-Up Edits

- Changing `Session.request()` or `Session.prepare_request()` to remove their
  existing `.upper()` calls was rejected. PO-002 proves repeated uppercasing is
  harmless for ASCII method tokens, and leaving those call sites unchanged
  preserves existing public construction behavior.
- Adding normalization in `HTTPAdapter.send()` was rejected. F-001 localizes the
  issue to prepared request construction. Normalizing again at the adapter would
  broaden the change to already prepared mutable objects without public intent
  evidence.
- Supporting non-ASCII method names was rejected as unsupported by the public
  issue. F-002 records that ambiguity.

## Next Tests To Add Later

Do not edit tests in this task. A future non-benchmark patch should add a
Python 2 regression test equivalent to:

```python
p = requests.Request(method=u'POST', url='http://example.test').prepare()
assert p.method == 'POST'
assert isinstance(p.method, str)
```

An integration variant with a multipart file body would cover the original
symptom path.

