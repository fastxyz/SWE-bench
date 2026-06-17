# FVK Notes

The FVK audit confirmed V1 rather than changing source code again.

`F1` identifies the public bug: inverse presentation-generator syllables were not translated back to permutation generators, causing valid identity homomorphisms such as `D3 -> D3` to be rejected. `PO1` and `PO2` are the relevant obligations, and V1 discharges them by building `gen_to_s` from relator symbols and applying the signed exponent from `r.array_form`.

`F2` explains why I kept V1's symbol-to-positive-generator mapping instead of mapping inverse free-group objects directly. `PO2` requires `x_i**-1` to evaluate as `images[g_i]**-1`; using the inverse permutation object as a key could be ambiguous if that object is also listed as a separate generator.

`F3` and `PO3` cover the non-permutation path. I kept V1 unchanged because, for `FpGroup` and `FreeGroup`, mapping a relator symbol to its own generator and using the signed exponent computes the same intended contribution as before.

`F4` and `PO5` cover compatibility. No public signatures, return types, accepted input types, or tests were changed, so no additional compatibility patch is warranted.

`F5` and `PO6` record the verification boundary: no tests, Python snippets, or K tooling were run. The proof is constructed and documented in `fvk/PROOF.md`, with commands recorded for future checking, but it is not machine-checked in this environment.
