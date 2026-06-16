# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found that the V1 source change satisfies the
public Cython/autowrap intent and did not surface a justified production-code
revision.

## Trace to Findings and Proof Obligations

Finding F1 identifies the original bug: an explicit unused `MatrixSymbol` reached
the redundant-argument path and was synthesized as `InputArgument(x)` without
dimensions. Proof obligations PO1, PO4, and PO6 cover the repair: dimensions are
derived from `MatrixSymbol.shape`, the missing `name_arg_dict` path passes that
metadata into `InputArgument`, and C/Cython consumers then select pointer and
ndarray handling. Because these obligations are discharged by the constructed
proof, no additional Cython or autowrap edit is needed.

Finding F2 checks the scalar frame condition. PO3 and PO5 show that scalar
redundant arguments still receive empty metadata and existing argument objects
are reused unchanged. This is why I did not broaden the fix to make every
redundant argument array-like.

Finding F3 records the unshaped `IndexedBase` boundary. PO2 and PO7 justify the
V1 behavior for shaped indexed arrays, while an unshaped unused `IndexedBase`
has no public shape source in the issue. I kept V1 unchanged rather than adding
an invented shape declaration mechanism.

Finding F4 records the language-scope decision. PO8 limits this proof to the
C/Cython path named by the issue. I inspected the specialized Julia, Octave, and
Rust routine builders, but did not edit them because the public failure is
autowrap with the Cython backend and an incorrect generated C signature.

Finding F5 and PO9 capture the honesty boundary. I did not run tests, Python, or
K tooling, and I did not remove or edit any tests. The FVK proof is constructed,
not machine-checked.

## Artifacts Produced

The five requested FVK artifacts are complete:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The FVK formal and adequacy core is also present:

- `fvk/mini-codegen.k`
- `fvk/codegen-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

## Execution Status

No commands from the FVK materials were executed. The emitted commands in
`fvk/PROOF.md` are intended for later machine checking when a suitable
environment is available.
