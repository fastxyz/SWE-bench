# FVK Notes

The FVK audit keeps the V1 source fix unchanged. F-001 and PO-001 show that the reported mutation path is exactly `contribute_to_class()` adding `self.model`, while V1 hashes only `creation_counter`, so model attachment no longer changes the hash. PO-002 connects that stability to the issue's dictionary-membership reproducer, and PO-003 shows the unchanged `Field.__eq__()` still satisfies Python's equal-objects-have-equal-hashes rule.

I did not revise `Field.__eq__()` because no finding identifies equality as defective. PO-003 depends on the current equality definition and discharges the compatibility obligation with the V1 hash.

I did not preserve the old model-sensitive hash behavior for abstract-inherited fields. F-002 records the public test conflict, but PO-004 traces why unequal fields with the same hash are valid and why the issue text treats hash uniqueness as a non-requirement. This is why V1 is allowed to make those fields collide.

I did not add a cached or separate immutable hash key. F-003 records that direct user mutation of `creation_counter` is outside the issue's stated domain, and PO-001 only requires stability across Django's model attachment transition. Adding a new hash key would be a broader design change requiring its own equality audit.

Files added for the FVK pass: `fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, and `fvk/ITERATION_GUIDANCE.md` because PO-001 through PO-006 need a written spec, findings log, proof obligations, proof sketch, and next-iteration decision record. I also added the materialized K sketches `fvk/mini-field-hash.k` and `fvk/field-hash-spec.k` because F-004 and PO-006 require the formal core and the commands needed to machine-check it later. The source file `repo/django/db/models/fields/__init__.py` remains exactly as in V1.

No tests, Python code, or K tooling were run, per the task constraints. F-004 and PO-006 keep that proof limitation explicit.
