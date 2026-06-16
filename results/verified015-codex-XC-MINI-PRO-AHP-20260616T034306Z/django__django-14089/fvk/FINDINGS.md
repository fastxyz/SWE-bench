# FVK Findings

Status: no blocking findings. V1 stands.

F-001: Missing reverse data-model hook in the baseline source.

* Evidence: E-001 says `OrderedSet` should be accepted by `reversed()`.
* Pre-V1 observed behavior, by static Python data-model reasoning:
  `OrderedSet` had `__len__()` but no `__getitem__()` and no `__reversed__()`,
  so `reversed(OrderedSet([1, 2, 3]))` could not obtain a reverse iterator.
* Expected behavior: reverse iteration yields `[3, 2, 1]`.
* V1 status: fixed by adding `OrderedSet.__reversed__()`.
* Related proof obligations: PO-001, PO-003.

F-002: Duplicate inputs must reverse the set contents, not the raw constructor input.

* Evidence: E-003 identifies `OrderedSet` as a set preserving insertion order.
* Example: `OrderedSet([1, 2, 1])` has forward contents `[1, 2]`; expected
  reverse contents are `[2, 1]`, not `[1, 2, 1]` reversed.
* V1 status: satisfied because the method reverses `self.dict`, the existing
  deduplicated backing store.
* Related proof obligations: PO-002, PO-005.

F-003: Runtime support for `reversed(self.dict)` is a necessary side condition.

* Evidence: E-005 states `python_requires = >=3.8`.
* Expected behavior: dictionary key order is reversible in the supported runtime
  domain.
* V1 status: satisfied; no fallback list copy is required.
* Related proof obligations: PO-003, PO-006.

F-004: Compatibility risk from adding `__reversed__()` is low.

* Evidence: the V1 change adds a new Python data-model hook and does not change
  any existing method signatures or return shapes.
* Expected behavior: existing public callers of `OrderedSet` remain compatible.
* V1 status: satisfied.
* Related proof obligations: PO-004, PO-007.

## Proof-derived Findings

No proof-derived source-code defect was found. The only residual risk is that
the K proof is constructed but not machine-checked; this affects confidence in
the artifact, not the static source-code conclusion.
