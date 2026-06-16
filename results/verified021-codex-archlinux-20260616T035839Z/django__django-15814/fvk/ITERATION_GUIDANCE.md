# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged. The FVK audit found the pre-fix bug mechanism and the V1
line-level fix discharges the relevant proof obligations.

## Source changes for V2

No additional source change is justified by the public issue or the proof
obligations.

## Follow-up when execution is available

Run the recorded FVK commands in `fvk/PROOF.md` in a K-enabled environment.
Run Django's relevant proxy-model test subset in a normal Django test
environment. Those commands are intentionally not run here.

## Test guidance

When test edits are allowed, add a regression test using the existing public
shape:

```python
qs = Issue.objects.select_related("assignee").only("assignee__status")
self.assertEqual(qs.get(), issue)
```

Keep tests until both the K claims and Django tests have been run externally.

## Future audit boundary

If a future report covers proxy-specific reverse relations or a different
`defer()` path, audit that as a separate intent item. The current proof covers
valid `only()`/`select_related()` paths where the selected related fields are
concrete fields owned by the proxy target's concrete model.

