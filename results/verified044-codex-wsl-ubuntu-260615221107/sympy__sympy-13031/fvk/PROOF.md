# PROOF.md

Status: constructed, not machine-checked. No K tooling, Python, or tests were
run.

## Claims Proved by Construction

The K claims in `sparse-join-spec.k` encode PO1 through PO7. PO8 is discharged
by source-level compatibility inspection in `PUBLIC_COMPATIBILITY_AUDIT.md`.

The proof uses a reduced shape semantics because the defect and all public
expected values are shape-only. This abstraction is property-complete for the
issue: the predecessor behavior maps the horizontal zero-row example to
`shape(0,3)`, while V1 maps it to `shape(0,6)`.

## Symbolic Proof Sketch

### Row Join

For `shape(R1, 0)` joined with `shape(R2, C2)`, the first row-join semantic
rule fires and rewrites directly to `shape(R2, C2)`. This discharges PO1.

For `shape(R, C1)` joined with `shape(R, C2)` and `C1 =/= 0`, the compatible
row-join rule fires and rewrites to `shape(R, C1 +Int C2)`. This discharges
PO2.

For nonzero `C1` and unequal row counts, the error rule fires. This discharges
the row half of PO7.

### Col Join

For `shape(0, C1)` joined above `shape(R2, C2)`, the first col-join semantic
rule fires and rewrites directly to `shape(R2, C2)`. This discharges PO3.

For `shape(R1, C)` joined above `shape(R2, C)` and `R1 =/= 0`, the compatible
col-join rule fires and rewrites to `shape(R1 +Int R2, C)`. This discharges
PO4.

For nonzero `R1` and unequal column counts, the error rule fires. This
discharges the col half of PO7.

### HStack Zero-Row Family

`hstackShapes` reduces left-to-right through `hstackAcc`.

Starting with `shape(0, C0)`, joining `shape(0, C1)` uses the row-join rule.
If `C0 == 0`, PO1 gives `shape(0, C1)`, which equals
`shape(0, C0 + C1)`. If `C0 != 0`, PO2 gives `shape(0, C0 + C1)`.
Repeating the same step with `C2` and `C3` yields
`shape(0, C0 + C1 + C2 + C3)`. This discharges PO5.

### VStack Zero-Column Family

`vstackShapes` reduces left-to-right through `vstackAcc`.

Starting with `shape(R0, 0)`, joining `shape(R1, 0)` uses the col-join rule.
If `R0 == 0`, PO3 gives `shape(R1, 0)`, which equals
`shape(R0 + R1, 0)`. If `R0 != 0`, PO4 gives `shape(R0 + R1, 0)`.
Repeating the same step with `R2` and `R3` yields
`shape(R0 + R1 + R2 + R3, 0)`. This discharges PO6.

## Adequacy Gate

- Intent spec exists: `INTENT_SPEC.md`.
- Evidence ledger exists: `PUBLIC_EVIDENCE_LEDGER.md`.
- Formal English exists: `FORMAL_SPEC_ENGLISH.md`.
- Claim audit exists and passes: `SPEC_AUDIT.md`.
- Compatibility audit exists and passes: `PUBLIC_COMPATIBILITY_AUDIT.md`.

No formal-English claim is weaker than the issue intent, and no claim preserves
the legacy sparse `(0, 3)` behavior.

## Machine-Check Commands

These commands are emitted for a future environment with K installed. They were
not executed in this session.

```sh
kompile fvk/mini-sparse-join.k --backend haskell
kast --backend haskell fvk/sparse-join-spec.k
kprove fvk/sparse-join-spec.k
```

Expected machine-check result after installing K and running the commands:
`kprove` returns `#Top` for all claims.

## Test Recommendation

Do not delete tests in this benchmark. If the K proof is later machine-checked,
shape-only unit tests for the in-domain horizontal and vertical zero-dimension
families are subsumed by PO5 and PO6, but integration tests, type/return-class
tests, and any out-of-domain ShapeError tests should be kept.
