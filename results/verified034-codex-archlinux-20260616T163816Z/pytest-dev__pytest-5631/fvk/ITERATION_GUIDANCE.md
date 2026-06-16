# FVK Iteration Guidance

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## Verdict

V1 stands unchanged.

The FVK audit found the original problem as F-001 and discharged the relevant
proof obligations with the existing V1 identity predicate:

```python
any(p.new is s for s in sentinels)
```

No finding requires an additional production-code change.

## Decisions

Keep V1 source unchanged.

Reason: PO-001 proves the key safety property for the issue: explicit `new=`
objects are not equality-compared. PO-002 through PO-004 prove the cardinality
behavior for default sentinels, explicit non-sentinels, and mixed patching
lists. F-001 is therefore resolved and F-002/F-003 are confirmed.

Do not special-case NumPy arrays.

Reason: F-001 is about equality-based membership on arbitrary explicit `new=`
objects, not only NumPy arrays. PO-001's identity-only predicate handles the full
class of explicit replacements with unusual equality behavior.

Do not catch `ValueError` around the old membership test.

Reason: catching one exception would still invoke arbitrary equality logic and
would not satisfy PO-001. Identity comparison is the direct sentinel contract.

Do not refactor the helper further.

Reason: F-004 found no compatibility issue and PO-007 is discharged. Further
cleanup would be unrelated to the reported bug.

Do not remove tests.

Reason: F-005 records that the proof is constructed, not machine-checked, and
the benchmark forbids modifying test files.

## Next Useful Work

When tests can be edited in a normal development setting, add focused tests for
the three test-guidance bullets in `fvk/PROOF.md`.

When K tooling is available, run the commands in `fvk/PROOF.md` and keep the
formal artifacts aligned with any syntax adjustments required by that K version.
