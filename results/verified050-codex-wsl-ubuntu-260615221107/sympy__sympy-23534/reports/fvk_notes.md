# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found the same root cause as the baseline:
the iterable branch of `symbols()` lost the keyword-only `cls` argument during
recursive calls. The V1 source change, `symbols(name, cls=cls, **args)`,
discharges the relevant proof obligations without requiring another source edit.

## Trace to Findings and Proof Obligations

Finding F1 identifies the production bug: iterable recursion dropped `cls`,
which explains the reported `Symbol` result for
`symbols(('q:2', 'u:2'), cls=Function)`. PO1 and PO2 require the concrete issue
input to construct `Function('q0')` and localize the pre-fix failure. PO3
requires recursive class preservation for the general `cls` mechanism. V1
directly satisfies all three by forwarding `cls=cls`.

Finding F2 checks that the extra iterable layer still produces separate output
groups. PO4 and PO7 require preserving output shape and public compatibility.
V1 does not change `result.append(...)` or `type(names)(result)`, so no further
edit is justified.

Finding F3 checks keyword-argument preservation. PO5 and PO6 require the string
and range branches, assumptions, and other `**args` behavior to remain intact.
V1 leaves the string/range branch unchanged and continues to pass `**args`.

Finding F4 records the honesty limitation: the proof is constructed, not
machine-checked. PO8 requires commands to be written but not executed in this
benchmark. No tests, Python, `kompile`, `kast`, or `kprove` were run.

## Files Changed in the FVK Phase

No production source file was changed during the FVK phase. The existing V1
production change in `repo/sympy/core/symbol.py` remains the final source fix.

Added FVK artifacts under `fvk/`: `SPEC.md`, `FINDINGS.md`,
`PROOF_OBLIGATIONS.md`, `PROOF.md`, `ITERATION_GUIDANCE.md`,
`INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`, `FORMAL_SPEC_ENGLISH.md`,
`SPEC_AUDIT.md`, `PUBLIC_COMPATIBILITY_AUDIT.md`, `mini-symbols.k`, and
`symbols-spec.k`.

Added this report at `reports/fvk_notes.md`.

## Alternatives Reconsidered

A `Function`-specific branch was rejected again because F1 and PO3 trace the
bug to general `cls` propagation, and the public docs describe `cls` as applying
to symbol-like classes generally.

A larger refactor of `symbols()` argument handling was rejected because PO3 and
PO6 are satisfied by explicit recursive forwarding while preserving the existing
`**args` behavior.
