# FVK Findings

Status: constructed, not machine-checked. Findings are based on static inspection and formal reasoning only.

## F-001: Pre-V1 crash on relation field with omitted `to`

Classification: code bug fixed by V1.

Input class: a field where `field.remote_field` and `field.remote_field.model` are truthy, but `deep_deconstruct(field)[2]` does not contain `"to"`.

Observed before V1: `del deconstruction[2]['to']` raises `KeyError`.

Expected: the autodetector should ignore relation targets for rename comparison and proceed with the field's deconstruction unchanged except for removing `"to"` if present.

Evidence: `benchmark/PROBLEM.md` provides a custom `ForeignKey` subclass that hardcodes `to` during initialization and removes it from `deconstruct()`.

Resolution: V1 changed the operation to `deconstruction[2].pop('to', None)`, which is total for the missing-key case.

Related proof obligations: PO-001, PO-003.

## F-002: V1 preserves relation-target erasure when `to` is present

Classification: confirmation of preserved behavior.

Input class: a relational field whose deconstructed kwargs include `"to"`.

Observed in V1: `pop('to', None)` removes `"to"` and preserves all other deconstruction components.

Expected: relation target must be ignored during model rename comparison.

Resolution: no further code change required.

Related proof obligations: PO-002, PO-005.

## F-003: V1 preserves non-relation field behavior

Classification: confirmation of preserved behavior.

Input class: a non-relational field, including a hypothetical field whose kwargs contain a key named `"to"` for its own non-relation semantics.

Observed in V1: the branch condition is unchanged, so non-relation deconstructions are appended without deleting any key.

Expected: only related-field targets should be ignored.

Resolution: no further code change required.

Related proof obligations: PO-004, PO-005.

## F-004: Adjacent `generate_renamed_fields()` access is already guarded

Classification: no additional bug found in adjacent code.

Input class: renamed-field detection comparing old and new field deconstructions.

Observed in source: `old_field_dec[2]['to']` is read only under `and 'to' in old_field_dec[2]`.

Expected: the FVK repair should not broaden the patch to unrelated paths without a failing obligation.

Resolution: no source change required.

Related proof obligations: PO-006.

## F-005: Non-dict deconstruction kwargs remain outside the contract

Classification: precondition / out-of-domain behavior.

Input class: a malformed field whose `deconstruct()` returns a third element that is not a dictionary.

Observed in source: `deep_deconstruct()` iterates `kwargs.items()`, so such a field would fail before the V1 `pop()` line.

Expected: Django's `Field.deconstruct()` contract requires keyword arguments to be represented as a dict.

Resolution: no source change required for this issue; handling malformed deconstructors would be a separate compatibility decision.

Related proof obligations: PO-007.

## F-006: Proof and test recommendations are not machine-checked

Classification: proof honesty gate.

Observed: this task prohibits running Python, tests, or K tooling.

Expected: artifacts must label the proof as constructed, not machine-checked, and must not recommend deleting tests based on an un-run proof.

Resolution: no tests were run or modified. Any future test removal would require real `kprove` discharge and normal Django test execution outside this session.

Related proof obligations: PO-008.
