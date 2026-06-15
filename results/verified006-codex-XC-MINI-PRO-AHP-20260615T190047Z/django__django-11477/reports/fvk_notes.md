# FVK Notes

## Decision

The V1 source fix stands unchanged. The FVK pass added verification artifacts under `fvk/` but did not make further edits under `repo/`.

## Trace From Findings And Proof Obligations

- Kept the fix in `_reverse_with_prefix()` rather than moving it to `translate_url()`: F1 identifies the reported translation failure as caused by keyword `None` reaching reverse candidate matching, and PO-1/PO-3 discharge the shared reverse-layer behavior. PO-6 confirms the public caller path from `translate_url()` remains compatible.
- Kept positional `None` filtering from V1: F2 traces the public `{% url 'my_view' obj.might_be_none %}` use case, and PO-2 requires positional `None` to be omitted before candidate matching.
- Kept the filter identity-specific to `None`: F3 records the empty-string template-variable concern, and PO-4 discharges preservation of empty strings and other non-`None` falsey values.
- Kept the existing mixed args/kwargs `ValueError` behavior unchanged: F4 confirms the check remains before normalization, and PO-5 records that ordering as a compatibility obligation.
- Left regex matching, converter calls, quoting, resolver population, and default checks untouched: F5 classifies these as model limits and unchanged frame conditions, and PO-7 records that V1 only changes the argument values entering the existing candidate-selection logic.

## Artifacts Produced

The five requested artifacts are complete:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also produced the additional FVK adequacy and formal-core files required by the kit documentation:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-python.k`
- `fvk/url-reverse-spec.k`

## Execution Notes

No tests, Python commands, or K tooling were run. The proof is constructed, not machine-checked, and the emitted commands in `fvk/PROOF.md` are for a future runtime-enabled environment.
