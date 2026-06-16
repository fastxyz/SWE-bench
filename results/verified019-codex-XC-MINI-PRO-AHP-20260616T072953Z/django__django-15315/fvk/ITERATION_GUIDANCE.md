# Iteration Guidance

Status: V1 stands unchanged.

## Decision

Keep the V1 source change:

```python
def __hash__(self):
    return hash(self.creation_counter)
```

This is justified by F-001 and proof obligations PO-001 through PO-003.

## Do Not Apply These Alternatives

Do not restore model metadata to `Field.__hash__()`. PO-001 shows that model-sensitive hashing recreates the reported hash mutation.

Do not change `Field.__eq__()`. PO-003 shows V1 remains compatible with the existing equality definition, and no finding identifies equality as the defect.

Do not add hash caching for this issue. F-003 records that arbitrary direct mutation of `creation_counter` is outside the public issue's domain; caching would add state and would require a separate equality compatibility audit.

Do not change abstract-field deepcopy behavior or assign new `creation_counter` values during copying. F-002 shows the only reason to do so would be preserving legacy hash inequality for unequal fields, which is not an intent obligation.

## Recommended Future Tests

Add a regression test for the reported dictionary-key scenario once test editing is allowed.

Update legacy assertions that require unequal hashes for unequal abstract-inherited fields. The intended public behavior is unequal field objects, not unique hashes.

Keep integration and ordering tests. The FVK proof covers only hash stability and equality/hash compatibility for `Field`.

## Next Verification Step

In an environment where K execution is allowed, run the commands in `fvk/PROOF.md`. Until then, treat the proof as constructed, not machine-checked, and do not remove tests based on it.
