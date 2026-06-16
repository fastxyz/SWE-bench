# FVK Notes

Status: V1 stands unchanged after the FVK audit. No tests, Python code, or K tooling were executed.

## Decisions

D1. Kept `ModelChoiceIteratorValue.__hash__()` as `return hash(self.value)`.

Trace: `fvk/FINDINGS.md` F1 identifies the original code bug as an unhashable wrapper during dictionary lookup. `fvk/PROOF_OBLIGATIONS.md` PO2 proves the wrapper hash is the wrapped value hash, PO3 proves hash/equality coherence, and PO4-PO5 prove dictionary membership/getitem for the issue's hashable-key scenario.

D2. Left the existing `__eq__()` implementation unchanged.

Trace: `fvk/FINDINGS.md` F2 confirms list membership already worked through value-based equality. `fvk/PROOF_OBLIGATIONS.md` PO1 shows the current `__eq__()` behavior is the required equality contract, and PO3 depends on preserving that contract.

D3. Did not replace the wrapper with the primitive prepared value.

Trace: `fvk/FINDINGS.md` F3 rejects that alternative because it would discard `.instance`. `fvk/PROOF_OBLIGATIONS.md` PO6 requires the wrapper payload and producer/consumer shape to remain framed, and PO7 requires compatibility with existing public call shapes.

D4. Did not add `__bool__()`.

Trace: `fvk/FINDINGS.md` F4 records the side-by-side alternative: truthiness parity would not affect the reported hash lookup failure and could change behavior for valid falsey prepared values such as `0`. `fvk/PROOF_OBLIGATIONS.md` PO7 does not require or justify that public behavior change.

D5. Did not special-case unhashable wrapped values.

Trace: `fvk/FINDINGS.md` F5 classifies unhashable wrapped values as outside the hash-table lookup domain. `fvk/PROOF_OBLIGATIONS.md` PO8 shows V1's delegation to `hash(self.value)` preserves Python's normal `TypeError` behavior for unhashable keys.

D6. Did not remove or edit tests.

Trace: `fvk/FINDINGS.md` F6 and `fvk/PROOF_OBLIGATIONS.md` PO9 record the honesty boundary: the proof is constructed, not machine-checked, and this task forbids test execution and test modification.

D7. Did not add special handling for deliberately asymmetric custom dictionary keys.

Trace: `fvk/FINDINGS.md` F7 and `fvk/PROOF_OBLIGATIONS.md` PO10 scope the dictionary proof to the public issue's ordinary integer-key case and to keys whose equality with the wrapper cooperates with wrapped-value equality. The public hint only justifies hash delegation to `self.value`.

## Result

No source edits were made during the FVK phase. The V1 source change remains the minimal production fix justified by public intent and by the constructed proof obligations.
