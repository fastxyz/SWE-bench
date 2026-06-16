# Spec Adequacy Audit

Status: constructed, not machine-checked.

A1. C1 vs I3-I4: pass. It states an explicit sentinel rather than a fabricated
finite probability threshold.

A2. C2 vs I4: pass. It proves that prepending `Inf` preserves the boundedness
of all finite observed probability thresholds.

A3. C3 vs I2-I3: pass. It preserves the threshold comparison rule and the
initial no-prediction point.

A4. C4 vs E1-E2: pass as a bug witness. It is intentionally not a desired
postcondition.

A5. C5 vs I3 and the issue workaround: pass as a rejected alternative. It
shows clipping does not satisfy the no-prediction obligation when max score is
exactly 1.

A6. Scope limits: pass with caveat. The formal model covers the changed
sentinel prepend behavior, not the full Python/NumPy implementation. This
caveat is recorded as FINDINGS F-4 and PO-7.
