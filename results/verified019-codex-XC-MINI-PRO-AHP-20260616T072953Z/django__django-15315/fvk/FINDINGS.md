# FVK Findings

Status: constructed, not machine-checked. No tests, Python code, or K tooling were executed.

## F-001: V1 Satisfies The Reported Hash-Mutation Bug

Input: a `Field` instance with `creation_counter = C` and no attached model is inserted into a dictionary, then `contribute_to_class()` attaches it to a model.

Pre-V1 observed behavior: `hash(field)` depended on `(C, app_label, model_name)`, so the value changed when `self.model` was assigned.

V1 expected and observed by inspection: `hash(field)` depends only on `C`, so the value is unchanged by model attachment.

Classification: code bug fixed by V1.

Proof trace: PO-001 and PO-002.

Recommended action: keep the V1 source change.

## F-002: Legacy Public Test Expects Unnecessary Hash Inequality

Input: fields copied from an abstract base model can share a `creation_counter` while being attached to different models.

V1 observed by inspection: such fields can have the same hash because the hash is now `hash(creation_counter)`.

Legacy public-test expectation: `repo/tests/model_fields/tests.py` asserts `hash(abstract_model_field) != hash(inherit_model_field)` for unequal abstract-inherited fields.

Expected per public issue: unequal objects may share a hash because equality still distinguishes them. The issue explicitly says, "Objects with the same hash are still checked for equality."

Classification: SUSPECT legacy public-test obligation, not a production code bug.

Proof trace: PO-003 and PO-004.

Recommended action: do not change production code to preserve this stronger hash-distribution behavior. A future test update should assert field inequality and ordering, but not unequal hash values.

## F-003: Direct Mutation Of `creation_counter` Is Outside The Proven Domain

Input: user code manually changes `field.creation_counter` after using the field as a dictionary key.

V1 observed by inspection: because `Field.__hash__()` returns `hash(self.creation_counter)`, this direct mutation would change the hash value.

Expected per public issue: not specified. The report concerns model-class assignment changing hash through `self.model`, not arbitrary mutation of internal ordering state.

Classification: underspecified intent / out-of-domain edge case for this repair.

Proof trace: PO-001 domain assumption.

Recommended action: no source change for this issue. If future public intent requires immutability under arbitrary `creation_counter` mutation, audit a separate immutable hash key together with `Field.__eq__()` compatibility.

## F-004: Formal Proof Was Constructed But Not Machine-Checked

Input: `fvk/mini-field-hash.k` and `fvk/field-hash-spec.k` are written as the formal core.

Observed: no `kompile`, `kast`, or `kprove` command was run because the task forbids K tooling execution.

Expected: proof claims remain "constructed, not machine-checked" until the commands in `fvk/PROOF.md` are executed in an environment with K.

Classification: proof honesty gate / residual verification risk.

Proof trace: PO-006.

Recommended action: keep tests until machine checking is performed; do not delete or modify tests in this task.
