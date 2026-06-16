# FVK Notes

## Decision

V1 stands unchanged. No production source files were edited during the FVK
phase.

## Trace to FVK Findings and Proof Obligations

`fvk/FINDINGS.md` F1 identifies the original defect: class descriptions could
receive a class-level `Return type` field from a constructor annotation.
`fvk/PROOF_OBLIGATIONS.md` PO1 states the required postcondition for this path:
for `objtype == "class"`, parameter annotations remain recorded but `"return"`
is absent. The V1 guard in `record_typehints()` satisfies that obligation, so no
additional source change is needed.

F2 explains why the old public test expectation of class-level `Return type:
None` is not a reason to revert V1. PO1 is derived from the issue's expected
behavior, while the legacy test encodes the reported bug and is marked SUSPECT
in `fvk/SPEC.md`.

F3 checks the main over-fix risk: suppressing return types for functions or
methods. PO3 requires function and method return annotations to remain recorded.
V1's condition excludes only `class` and `exception`, so function and method
behavior is preserved.

F4 covers the only intentional generalization beyond the literal `autoclass`
wording. PO2 applies the same no-constructor-return rule to `exception`, because
public docs describe exceptions as exception classes and the implementation uses
`ExceptionDocumenter(ClassDocumenter)`. I kept that part of V1 because the
generalization is class-like and supported by public evidence.

PO4 ties the recorder change to the rendered symptom: both merge helpers create
`rtype` only when a recorded `"return"` annotation exists. That makes the V1
change sufficient for the reported output path without editing
`merge_typehints()`.

## Residual Assumption

The proof assumes the normal autodoc event path controls the annotation entry
for the object currently being documented. If a third-party extension manually
pre-populates `env.temp_data['annotations'][name]['return']` for the same class
before merge time, V1 does not remove that external state. The FVK artifacts
classify that as outside the public issue path, not as a blocker for this fix.

## Verification Status

The proof is constructed, not machine-checked. I emitted the K-shaped artifacts
and commands in `fvk/SPEC.md` and `fvk/PROOF.md`, but did not run `kompile`,
`kast`, `kprove`, tests, or Python code, per the task constraints.
