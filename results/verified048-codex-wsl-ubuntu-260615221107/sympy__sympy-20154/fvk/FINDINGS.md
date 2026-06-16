# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public intent, source inspection, and proof obligations. No tests or project code were run.

## F-001: Legacy output aliasing is the reported bug

- Evidence: E-001, E-003.
- Concrete input: retaining multiple outputs from `partitions(6, k=2)`, for example with `list(partitions(6, k=2))`.
- Pre-fix observed behavior: multiple list entries referred to the same working dictionary, so later mutations made earlier retained entries appear as the final partition.
- Expected behavior: each retained entry keeps the partition contents it had when yielded.
- Obligation trace: PO-001, PO-002, PO-004.
- V1 status: discharged. The normal yield path now returns `ms.copy()`.

## F-002: `size=True` has the same aliasing surface

- Evidence: E-006.
- Concrete input: retaining outputs from `partitions(6, k=2, size=True)`.
- Pre-fix observed behavior: each tuple's dictionary component `P` could alias the same mutable working dictionary.
- Expected behavior: each tuple's `P` is a stable snapshot, while `M` remains the multiplicity sum for that snapshot.
- Obligation trace: PO-003, PO-006.
- V1 status: discharged. The size-mode yield path now returns `(sum(ms.values()), ms.copy())`.

## F-003: Caller mutation of a yielded dictionary should not corrupt iteration

- Evidence: E-004.
- Concrete input: consume one partition dictionary, mutate it externally, then continue the generator.
- Pre-fix observed behavior: mutating the yielded object could mutate the generator's own working dictionary because they were the same object.
- Expected behavior: yielded dictionaries are public snapshots, not the private mutable state.
- Obligation trace: PO-001, PO-002.
- V1 status: discharged for multi-yield paths by copying at each yield boundary.

## F-004: Full enumeration correctness is not re-proved by this FVK pass

- Evidence: E-005, E-007, IS-006.
- Concrete input class: all valid `n`, `m`, and `k` combinations.
- Observed status: V1 does not alter the enumeration transition, but the constructed K model abstracts it as `STATES`.
- Expected behavior: the pre-existing algorithm still enumerates the documented partition dictionaries with existing `m` and `k` filtering.
- Obligation trace: PO-004, PO-008.
- V1 status: no code change required. This is an explicit proof boundary, not a discovered V1 defect. Existing public tests should be kept unless a future full enumeration proof is machine-checked.

## F-005: The old docstring caveat was SUSPECT legacy evidence

- Evidence: E-001, E-002, E-003.
- Concrete text: the old warning said the same dictionary object was returned each time and told users to call `.copy()`.
- Expected behavior: documentation should no longer describe the defect as intended usage.
- Obligation trace: PO-007.
- V1 status: discharged. V1 removed the warning and added direct `list(partitions(...))` examples.

## Proof-derived Findings from `/verify`

No additional code bug was found. The proof construction leaves two honest boundaries:

- PB-001: The K artifacts are constructed but not machine-checked. Do not remove tests based on them until `kprove` returns `#Top`.
- PB-002: The formal model proves the snapshot boundary over an abstract sequence of maps, not the full integer-partition enumeration algorithm.
