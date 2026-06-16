# Formal Spec English

This paraphrases the nontrivial claims in `partitions-snapshot-spec.k`.

C-001: For any abstract sequence of partition maps `STATES`, `collect(STATES)` terminates with an output list of fresh object ids allocated consecutively from the initial `nextId`. The heap entry for the `i`-th fresh id is extensionally equal to the `i`-th map in `STATES`.

C-002: For any abstract sequence of `(size, partition-map)` states, `collectSize(STATES)` terminates with an output list of `(size, fresh-id)` pairs allocated consecutively from the initial `nextId`. Each fresh id's heap entry is extensionally equal to the paired partition map, and the size component is preserved.

C-003: The abstract `STATES` sequence represents the unchanged integer-partition enumeration performed by the existing algorithm. The formal claims prove the snapshot boundary introduced by `dict.copy()` and do not independently prove that the algorithm enumerates exactly all integer partitions.

C-004: The proof is partial correctness only and is constructed, not machine-checked. It does not establish termination or performance bounds.
