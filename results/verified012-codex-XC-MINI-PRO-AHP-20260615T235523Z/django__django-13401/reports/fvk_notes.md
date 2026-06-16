# FVK Notes

The FVK audit confirms V1 unchanged. `fvk/FINDINGS.md` identifies the original
bug as FVK-F1: abstract-field copies with the same `creation_counter` but
different owners compared equal. `fvk/PROOF_OBLIGATIONS.md` discharges that
with PO-EQ-OWNER and PO-SET-CARDINALITY, matching the V1 equality check that
includes `getattr(field, 'model', None)`.

No source edit was made during the FVK pass because the remaining obligations
also align with V1. FVK-F2 maps to PO-HASH-CONSISTENCY: hashing uses the same
identity tuple as equality. FVK-F3 maps to PO-LT-PRIMARY-COUNTER: different
creation counters return the old counter comparison before any model key is
consulted. FVK-F4 maps to PO-LT-COLLISION: equal-counter fields use the model
sort key as the requested collision tie-breaker.

I rejected changing abstract-field copying because PO-ABSTRACT-CLONE shows the
copying behavior is the source condition that exposes the bug, not the behavior
the issue asks to remove. Changing copied creation counters would undermine the
creation-order semantics captured by E6/E8 and PO-LT-PRIMARY-COUNTER.

I also rejected a model-first ordering rewrite because FVK-F3 and
PO-LT-PRIMARY-COUNTER trace directly to the issue's warning that model-first
ordering broke an existing test. V1 only uses the model after equal counters.

The proof remains constructed, not machine-checked, as recorded in FVK-F5 and
`fvk/PROOF.md`. No tests, Python code, or K tooling were run.
