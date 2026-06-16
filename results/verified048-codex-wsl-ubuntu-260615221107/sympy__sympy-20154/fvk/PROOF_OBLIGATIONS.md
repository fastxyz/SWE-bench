# Proof Obligations

Status legend: `discharged by V1` means discharged by static source inspection plus the constructed proof. It does not mean machine-checked.

## PO-001: Fresh output object for each normal yield

- Evidence: E-001, E-002, E-004.
- Statement: On each `size=False` yield from the iterative path, the public dictionary object is freshly allocated and is not the internal mutable `ms` dictionary.
- Code location: `repo/sympy/utilities/iterables.py`, `yield ms.copy()`.
- Status: discharged by V1.

## PO-002: Snapshot content is stable after later generator mutations

- Evidence: E-003, E-004.
- Statement: For each yielded dictionary `D`, `D` is extensionally equal to `ms` at yield time and later updates to `ms` do not update `D`.
- Formal claim: `collect(STATES)` in `partitions-snapshot-spec.k`.
- Status: discharged by V1.

## PO-003: `size=True` snapshots the dictionary component

- Evidence: E-006.
- Statement: On each `size=True` yield, the tuple's dictionary component is a fresh snapshot, while the size component is computed from the same yield-time state.
- Code location: `yield sum(ms.values()), ms.copy()`.
- Formal claim: `collectSize(STATES)` in `partitions-snapshot-spec.k`.
- Status: discharged by V1.

## PO-004: Value sequence and filtering are preserved

- Evidence: E-005, E-007.
- Statement: Replacing `yield ms` with `yield ms.copy()` preserves dictionary equality, generator order, and the existing `m`/`k` filtering decisions.
- Reason: `dict.copy()` creates a new object with the same key-value bindings and does not mutate `ms`, `keys`, or `room`.
- Status: discharged by V1 for the changed behavior; full enumeration correctness remains a frame condition.

## PO-005: Single-yield boundary cases are compatible

- Evidence: existing docstring/test convention for empty/impossible partitions.
- Statement: Branches yielding `{}` or `(0, {})` once do not reuse a mutable dictionary across multiple yields and are fresh within that call.
- Code location: early return branch for `n <= 0`, invalid `m`, invalid `k`, or impossible `m*k < n`.
- Status: discharged by V1 unchanged.

## PO-006: Public API and callsites remain compatible

- Evidence: E-005, E-006, E-008.
- Statement: The function signature, return type, tuple shape, and dictionary API remain unchanged.
- Status: discharged by V1.

## PO-007: Documentation no longer instructs users to work around the bug

- Evidence: E-001, E-002, E-003.
- Statement: The public docstring should not preserve the old "same dictionary object" caveat as intended behavior.
- Status: discharged by V1.

## PO-008: Honesty boundary for unproved properties

- Evidence: FVK honesty gate, IS-006.
- Statement: The FVK proof must not claim machine checking, total correctness, performance bounds, or full enumeration correctness.
- Status: discharged by artifact wording. These remain residual proof boundaries, not V1 code bugs.
