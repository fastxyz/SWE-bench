# Iteration Guidance

V2 decision: keep V1 source unchanged.

## Justification

F-001 identifies the original bug as the missing `__reversed__()` data-model
hook, and PO-003 is discharged by the V1 source line `return reversed(self.dict)`.

F-002 confirms that duplicate inputs should be handled through the existing set
contents, not by reversing the raw constructor input. PO-002 and PO-005 are
discharged because V1 reverses the deduplicated backing dictionary.

F-003 confirms the only runtime side condition: dictionary reverse iteration
must be supported. PO-006 is discharged by the local `python_requires = >=3.8`
metadata, so no compatibility fallback or list copy is warranted.

F-004 and PO-007 show that adding `__reversed__()` is additive and compatible
with existing public uses.

## Recommended Next Actions

* Leave `repo/django/utils/datastructures.py` as V1.
* Do not edit tests in this benchmark task.
* In a normal development environment, add or keep a public unit test for
  `list(reversed(OrderedSet([1, 2, 3]))) == [3, 2, 1]` and a duplicate case.
* When K tooling is available, run the commands recorded in `fvk/PROOF.md`.
