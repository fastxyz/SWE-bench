# Formal Spec in English

Status: constructed, not machine-checked.

Claim `RESTORE-POSTAGGS`: Starting with `postPos = 0`, a cache suffix containing exactly `P` post-aggregator values, and an output row, running the modeled post-aggregator restore loop writes value `i` to row slot `START + i` for every `0 <= i < P` and consumes the suffix.

Claim `RESTORE-POSTAGGS-LOOP`: Starting from any intermediate state with `postPos = I`, `0 <= I <= P`, and exactly `P - I` post-aggregator values remaining, running the loop restores each remaining value to slots `START + I` through `START + P - 1` and exits with `postPos = P`.

Frame condition: the model does not change timestamp, dimension, aggregator, cache-key, public method signature, or serialized producer format behavior; those are outside the changed loop and are preserved by diff inspection.
