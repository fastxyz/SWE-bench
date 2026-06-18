# FVK Notes

## Decision

V1 stands unchanged.

The FVK audit produced no concrete counterexample and no unmet proof obligation
that V1 demonstrably fails. Therefore the revision discipline does not justify a
source edit.

## Artifact Trace

The formal core is under `fvk/`:

- `fvk/mini-blockmatrix.k` models the relevant `_blockmul` fragment.
- `fvk/blockmul-spec.k` states the K reachability claims.
- `fvk/PROOF.md` gives the constructed proof and exact commands that would be
  used for later machine-checking.
- `fvk/FINDINGS.md` records the audit findings and no-change decision.

## Why V1 Stands

`fvk/FINDINGS.md` finding F1 and claims `NORMALIZE-SCALAR-ZERO`,
`BLOCKMUL-COMPATIBLE-ZERO-ENTRY`, and `BLOCKMUL-REPEATED-SAFE` confirm the
reported defect mechanism: raw scalar zero block-product entries are normalized
to shaped zero matrices, so later block-size access has `.rows`/`.cols`.

`fvk/FINDINGS.md` finding F2 and claims `NORMALIZE-MATRIX-PRESERVE` and
`BLOCKMUL-COMPATIBLE-MATRIX-ENTRY` confirm the main regression condition:
matrix-valued block-product entries are preserved unchanged.

`fvk/FINDINGS.md` finding F3 and claims `BLOCKMUL-NONBLOCK-FALLBACK` and
`BLOCKMUL-INCOMPATIBLE-FALLBACK` confirm the fallback branches remain unchanged.

`fvk/SPEC_AUDIT.md` marks all intent obligations as covered by the formal
English spec. `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` found no signature,
dispatch, callsite, or override compatibility issue that requires a code change.

## Execution Boundary

No tests, Python code, `kompile`, or `kprove` commands were run. The proof is
constructed, not machine-checked, as recorded in `fvk/PROOF.md`.

## Alternatives Rejected

No alternative source edit was applied because no FVK finding implicated code
beyond V1's scalar-zero normalization in `_blockmul`. The audit's regression
argument in `fvk/PROOF.md` shows that broadening the change would add unproven
surface without a documented failing obligation.
