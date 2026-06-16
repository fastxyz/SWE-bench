# FVK Notes

## Decisions

1. Kept V1's helper-level fix unchanged.
   - Trace: `FINDINGS.md` F1 and F2 identify the pre-V1 bugs and mark them fixed.
   - Obligations: PO1, PO2, and PO3 are discharged by the constructed proof.
   - Reason: both reported public paths delegate to `as_compatible_data`, so the
     shared helper remains the correct repair point.

2. Kept the explicit unwrapping tuple as `pd.Series`, `pd.DataFrame`,
   `pdcompat.Panel`, and `xr.DataArray`.
   - Trace: F3 records the known-container compatibility frame condition.
   - Obligations: PO4 and PO7.
   - Reason: public intent calls for explicit type checking while preserving
     known xarray/pandas container behavior. `pdcompat.Panel` is included because
     this repository still has public construction support for it.

3. Did not move `pd.Index` into the new `.values` branch.
   - Trace: F3 and `PUBLIC_COMPATIBILITY_AUDIT.md` note that `pd.Index` already
     has an earlier adapter path.
   - Obligations: PO5 and rejected obligation R1.
   - Reason: changing `pd.Index` to use the later `.values` branch would be an
     unrelated compatibility change in this codebase.

4. Did not add scalar heuristics or a fallback generic `.values` read.
   - Trace: F1 identifies that generic `.values` access is the defect mechanism.
   - Obligations: PO1 and rejected obligation R3.
   - Reason: the public issue requires arbitrary `.values` objects to remain
     storable as objects, so a generic fallback would preserve the ambiguity.

5. Did not edit tests or run verification commands.
   - Trace: F4 and F5 record the proof capability boundary and test gap.
   - Obligations: PO8.
   - Reason: the task forbids running tests, Python, or K tooling, and forbids
     modifying test files.

## Artifacts

The FVK evidence package is under `fvk/`:

- `SPEC.md`
- `FINDINGS.md`
- `PROOF_OBLIGATIONS.md`
- `PROOF.md`
- `ITERATION_GUIDANCE.md`
- supporting adequacy and formal files:
  `INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`,
  `FORMAL_SPEC_ENGLISH.md`, `SPEC_AUDIT.md`,
  `PUBLIC_COMPATIBILITY_AUDIT.md`, `mini-python.k`, and
  `xarray-variable-spec.k`

## Outcome

V1 stands unchanged. The audit found no additional source edit justified by the
public intent or proof obligations.
