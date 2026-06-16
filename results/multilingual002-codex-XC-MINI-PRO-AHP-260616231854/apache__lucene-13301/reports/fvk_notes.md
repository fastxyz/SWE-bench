# FVK Notes

Status: constructed, not machine-checked.

The V1 changes to `XYPoint.equals` and `XYCircle.equals` stand. `fvk/FINDINGS.md`
entry F1 and `fvk/PROOF_OBLIGATIONS.md` PO-2/PO-3 show that `Float.compare` is the
right source repair because it distinguishes signed zero while preserving the existing
`Float.hashCode` formulas.

The FVK audit did surface an additional source problem, so V2 is not identical to V1.
F2 and PO-4 identify the same equals/hash contract violation in `Point`, `Circle`,
and `Rectangle2D`: those methods used primitive `==` over `double` fields while their
hashes remained signed-zero-sensitive. I changed those three `equals` methods to use
`Double.compare`, matching the existing `Rectangle` pattern and satisfying PO-5.

I left `XYRectangle` unchanged because F3 and PO-6 show that it already uses
`Float.compare` and `Float.floatToIntBits` consistently. I also left tests unchanged:
F4 and PO-7 classify primitive-comparison equality branches as suspect evidence for
this issue, and the task forbids test edits.

No tests or K tooling were run. F5 and PO-8 require the proof to remain labeled
constructed, not machine-checked; `fvk/PROOF.md` records the commands that would be
run in a suitable environment.
