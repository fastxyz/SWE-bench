# Spec Audit

Status: constructed, not machine-checked.

| Claim | Intent match | Reason |
| --- | --- | --- |
| C1 | PASS | E1-E6 require shuffling within each stratum and identify same-random-state-per-class as the defect. One shared stream gives different draw positions per class. |
| C2 | PASS | E2, E3, and E5 describe the legacy behavior as the bug; the formal legacy claim is included only to localize the failure mechanism. |
| C3 | PASS | E7 and existing source/tests say `random_state` is used only when shuffling and non-shuffled behavior should remain stable. |
| C4 | PASS | E8 requires repeated calls with an integer seed to be reproducible. Creating one fresh RNG per `_make_test_folds` call preserves that. |
| C5 | PASS | E9 and `check_random_state` source require stateful RNG objects to be returned and advanced, not reset. |
| C6 | PASS | E3's reproduced pairings are explained exactly by equal per-class permutations in the `n_splits == class_count` case. |

## Rejected over-specification

The issue says users expect different batches for different integer
`random_state` values. The audit does not encode a universal claim that every
distinct pair of seeds must yield distinct permutations for every dataset. That
stronger claim is not guaranteed by random number generators and is not needed
to fix the regression. The encoded obligation is that the implementation must
not structurally force identical per-class permutations by reseeding every class
with the same integer seed.

## Adequacy verdict

The formal English claims match the intent-only spec and do not preserve the
reported legacy behavior. The constructed proof can therefore justify `V2 == V1`
once the proof obligations are discharged by static inspection and, later, by
the emitted K commands if the toolchain is available.
