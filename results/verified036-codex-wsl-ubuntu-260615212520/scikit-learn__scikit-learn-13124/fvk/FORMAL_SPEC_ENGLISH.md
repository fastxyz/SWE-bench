# Formal Spec In English

Status: constructed, not machine-checked.

C1. `V1-INT-SEED-SHARED-RNG`: For `shuffle=True`, integer seed `S`, and two
equal-sized classes of size `N`, `makeTestFolds` returns abstract class
permutations `draw(S, 0, N)` and `draw(S, 1, N)`. The class permutations come
from consecutive draws of one RNG stream.

C2. `LEGACY-RESEED-BUG`: The legacy implementation that passes integer seed
`S` separately to each per-class splitter returns `draw(S, 0, N)` and
`draw(S, 0, N)` for the same two equal-sized classes. This is the mechanism that
forces identical class-pairing patterns.

C3. `NO-SHUFFLE-FRAME`: For `shuffle=False`, class assignments use ordered
fold positions and no RNG stream. This preserves the existing non-shuffled
behavior and avoids validating/consuming `random_state`.

C4. `INT-SEED-REPRODUCIBILITY`: Two independent calls with the same integer seed
start from the same abstract RNG state `rng(S, 0)`, so they produce the same
sequence of draw indexes for the same class-count list.

C5. `RNG-OBJECT-ADVANCES`: A stateful RNG object `rng(S, D)` is returned as
itself by `check_random_state`; assigning two classes consumes draw indexes `D`
and `D+1`. This preserves the expected stateful behavior of `RandomState`.

C6. `PAIRING-CONSEQUENCE`: In the issue's `n_splits == samples_per_class` case,
one sample from each class is assigned to each fold. Therefore equal per-class
permutations force fixed pairings, while consecutive per-class draw positions
allow pairings to change whenever those RNG draws differ.
