# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found no source-code defect that requires a V2 edit.

## Trace to Findings and Proof Obligations

- `FVK-1` identified the original missing operation registration. `PO-1` and `PO-2` show V1 resolves it by adding `POW("pow")` and delegating to `Math.pow`.
- `FVK-2` identified a cache-key correctness risk for non-commutative exponentiation. `PO-5` shows V1 resolves it by making `POW` preserve field order.
- `FVK-3` considered whether to add a `power` alias. `PO-8` rejects that change because public evidence supports `pow` as the native function spelling.
- `FVK-4` considered whether `pow` should be exactly binary. `PO-3` rejects that change because the existing arithmetic post-aggregator contract applies functions left-to-right over the fields list.
- `FVK-5` records the proof boundary around Java `Math.pow`. `PO-2` is still sufficient for this source fix because the public requirement is delegation/equivalence to that JDK primitive.
- `FVK-6` records documentation follow-up outside the benchmark source-code repair. It does not justify a production source edit.

## Files Changed in the FVK Phase

- No production source files were changed after V1.
- Added FVK artifacts under `fvk/`.
- Added this report at `reports/fvk_notes.md`.

## Commands Not Run

No tests, Python, K tooling, or project code were executed. The K commands are written in `fvk/PROOF.md` for later machine-checking only.
