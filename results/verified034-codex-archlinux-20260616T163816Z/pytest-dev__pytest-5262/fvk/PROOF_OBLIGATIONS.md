# PROOF_OBLIGATIONS.md

Status: constructed, not machine-checked.

## PO-1 - Text Wrapper Must Not Advertise Binary Mode

For every in-domain `EncodedFile` instance with buffer mode `M`,
`hasBinaryFlag(EncodedFile.mode)` must be false.

Evidence: E-001, E-002, E-004.

K claim: `MODE-NO-B`.

Finding trace: F-001, F-002.

Status: discharged by V1 source inspection and the constructed proof in
`fvk/PROOF.md`.

## PO-2 - Mode Getter Implements The Intended Transformation

For every in-domain buffer mode `M`, `EncodedFile.mode == stripB(M)`, where
`stripB` removes every `b` and preserves all other characters.

Evidence: E-003, E-005.

K claim: `MODE-GETTER`.

Finding trace: F-001.

Status: discharged. V1 implements `self.buffer.mode.replace("b", "")`.

## PO-3 - Non-Binary Mode Flags Are Preserved

For every in-domain buffer mode `M`, all non-`b` mode characters in `M` appear
in `EncodedFile.mode` in the same order and multiplicity.

Evidence: E-005.

K claim/lemma: `STRIPB-PRESERVES-NON-B`.

Finding trace: F-001.

Status: discharged by the definition of `stripB` and Python string
`replace("b", "")` semantics.

## PO-4 - Write Contract Remains Text-Oriented

On Python 3, `EncodedFile.write(bytes)` remains an error. The fix must make
callers choose text writes by advertising a text mode, not by widening
`write()`.

Evidence: E-002, E-004.

K coverage: modeled as an intent/frame condition, not as a new rewrite rule,
because V1 does not change `write`.

Finding trace: F-002.

Status: discharged by unchanged source.

## PO-5 - Underlying Buffer Mode Is Preserved

For every in-domain buffer mode `M`, `EncodedFile.buffer.mode == M` after the
wrapper mode is read.

Evidence: E-003 and the issue's distinction between wrapper and underlying
stream.

K claim: `BUFFER-MODE-PRESERVED`.

Finding trace: F-005.

Status: discharged. V1 only reads `self.buffer.mode`.

## PO-6 - Attribute Delegation Compatibility Is Preserved

For every attribute other than `mode` and class-defined properties, unknown
attribute access still delegates to the wrapped buffer.

Evidence: E-006.

K coverage: source-level frame obligation. No formal dispatch model is needed
for the changed attribute because the only new dispatch case is `.mode`.

Finding trace: F-003, F-005.

Status: discharged by unchanged `__getattr__`.

## PO-7 - Honesty Gate For Formal Tooling

The proof is constructed but not machine-checked. The emitted commands must be
recorded and not executed in this task.

Evidence: FVK `verify.md` honesty gate and the task's no-execution rule.

Finding trace: F-004.

Status: discharged by recording commands in `fvk/PROOF.md` without running
them.
