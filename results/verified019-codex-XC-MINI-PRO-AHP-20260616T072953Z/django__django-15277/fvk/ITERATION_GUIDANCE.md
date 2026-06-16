# FVK Iteration Guidance: django__django-15277

Status: constructed, not machine-checked.

## Decision

Keep V1 unchanged.

The FVK audit found that V1 discharges the public-intent obligations for the
reported issue:

- F1 is fixed by PO1, PO2, and PO4.
- F2 is satisfied by PO3 and PO5.
- F3 is satisfied by PO6.
- F4 records that no unresolved proof obstacle remains within the audited
  validator-state model.

## Next Code Action

No source edit is recommended beyond V1.

The current production change remains:

```python
if self.max_length is not None:
    self.validators.append(validators.MaxLengthValidator(self.max_length))
```

This is the narrowest edit that removes `MaxLengthValidator(None)` while
preserving bounded `CharField` behavior.

## Suggested Later Validation

These are not to be run in this restricted session:

```sh
kompile fvk/mini-python-charfield.k --backend haskell
kast --backend haskell fvk/charfield-spec.k
kprove fvk/charfield-spec.k
```

After the formal commands are machine-checked, run the normal Django test suite
in an environment where execution is available.

## Tests To Keep Or Add

Do not delete tests based on this constructed proof alone.

Useful coverage for a later environment:

- A regression check that a string `Value` resolves to a `CharField` without a
  `MaxLengthValidator(None)`.
- A preservation check that `CharField(max_length=L)` still includes a
  `MaxLengthValidator(L)` for non-`None` `L`.
- Existing system-check coverage for concrete `CharField()` without
  `max_length`, because the formal proof treats that as a frame condition.

## Open Questions

None that block the fix. The issue text directly specifies the guard shape and
the local source confirms that this guard covers the reported path.
