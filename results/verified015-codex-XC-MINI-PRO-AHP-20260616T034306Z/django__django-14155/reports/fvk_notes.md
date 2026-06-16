# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not justify additional production-code edits under the public issue intent and documented `resolve()` compatibility frame.

## Trace to findings and proof obligations

`fvk/FINDINGS.md` F-001 identifies the original bug: partial callbacks were displayed as `functools.partial` and their bound arguments were omitted from repr. V1 fixes this by unwrapping partials into display metadata in `ResolverMatch.__init__()`, which discharges `fvk/PROOF_OBLIGATIONS.md` PO-1 and PO-2.

F-002 confirms that V1 keeps `ResolverMatch.func`, `ResolverMatch.args`, `ResolverMatch.kwargs`, and tuple unpacking unchanged. This is required by PO-4 and by the public docs for `resolve()`. I kept V1's separate `_func_args` and `_func_kwargs` display fields rather than mutating the public runtime attributes for this reason.

F-003 confirms nested partials are covered. That maps to PO-2: the partial-unwrapping loop accumulates inner positional arguments before outer positional arguments and merges keyword maps so later partial bindings override earlier ones. PO-3 separately confirms non-partial repr behavior is preserved. This keeps the public nested-partial URL source shape in scope.

F-004 records a broader manual-construction edge where `ResolverMatch` could be instantiated outside the URL resolver's tuple-args domain. I did not edit production code for that because the public issue and docs target resolver-created matches, and PO-4's compatibility domain is the documented `resolve()` flow. This remains guidance for a separate API-hardening change if Django wants to support arbitrary manual constructor inputs.

F-005 records the no-execution constraint. PO-6 is discharged by labeling the proof constructed, not machine-checked, and by recording the `kompile`, `kast`, and `kprove` commands in `fvk/PROOF.md` without running them.

## Artifacts

The requested artifacts were produced:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The FVK adequacy/formal core was also produced under `fvk/`: `INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`, `FORMAL_SPEC_ENGLISH.md`, `SPEC_AUDIT.md`, `PUBLIC_COMPATIBILITY_AUDIT.md`, `mini-python-resolvermatch.k`, and `resolvermatch-spec.k`.

No tests, Python, or K tooling were run.
