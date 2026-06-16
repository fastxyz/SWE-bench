# FVK Specification: Field Hash Stability

Status: constructed, not machine-checked. No tests, Python code, or K tooling were executed.

## Scope

The audited unit is `django.db.models.fields.Field.__hash__()` and its interaction with:

- `Field.__init__()`, which assigns `creation_counter`.
- `Field.__eq__()`, which compares `creation_counter` and attached model.
- `Field.contribute_to_class()`, which assigns `self.model = cls` when a field is attached to a model class.

There are no loops or recursive functions in the audited unit.

## Intent Spec

I-001. Source: `benchmark/PROBLEM.md`.
Quoted evidence: "Field.__hash__ changes value when a field is assigned to a model class."
Semantic obligation: for a `Field` instance inserted into a dictionary before model attachment, assigning that same instance to a model must not change the value returned by `hash(field)`.
Status: encoded by PO-001 and the `FIELD-HASH-STABLE-ATTACH` claim.

I-002. Source: `benchmark/PROBLEM.md`.
Quoted evidence: "Objects with the same hash are still checked for equality"
Semantic obligation: unequal fields do not need distinct hashes. Hash collisions are acceptable if `Field.__eq__()` still distinguishes the objects.
Status: encoded by PO-004; used to classify legacy hash-inequality tests as suspect rather than binding.

I-003. Source: Python data model default-domain assumption.
Quoted evidence: hashable objects used in dictionaries must keep a stable hash while equal objects must have equal hashes.
Semantic obligation: if `field_a == field_b`, then `hash(field_a) == hash(field_b)`; the hash of a field must not change across normal Django model contribution.
Status: encoded by PO-002 and PO-003.

I-004. Source: `repo/django/db/models/fields/__init__.py`.
Quoted evidence: "Adjust the appropriate creation counter, and save our local copy."
Semantic obligation: `creation_counter` is the stable per-field construction/order component available before and after model attachment.
Status: accepted as a source-backed domain assumption for the Django-managed field lifecycle.

## Formal Model

The mini semantics models a field as `field(counter, model_key)`, where `model_key` is either `noModel` or `model(id)`.

Operations:

- `attach(field(C, old_model), model(M)) => field(C, model(M))`
- `eq(field(C1, M1), field(C2, M2)) => (C1 == C2 and M1 == M2)`
- `hash(field(C, M)) => C`

This abstraction keeps the property under verification visible: a passing implementation maps `hash(field(C, noModel))` and `hash(field(C, model(M)))` to the same value, while the pre-V1 implementation maps them to distinct values whenever the model key differs.

The K sketches are materialized in:

- `fvk/mini-field-hash.k`
- `fvk/field-hash-spec.k`

## Adequacy Audit

The formal claim that `hash(attach(field(C, noModel), model(M))) => C` matches I-001 because it models exactly the reported transition: a field with no model becomes attached to a model.

The formal claim that `hash(field(C, M)) => C` matches I-002 and I-003 because it preserves equality compatibility without requiring unique hashes for unequal fields.

No claim preserves the legacy behavior that abstract-inherited fields with equal `creation_counter` but different models must have unequal hashes. That behavior is stronger than Python requires and conflicts with I-002.

## Public Compatibility Audit

Changed public symbol: `Field.__hash__()`.

Compatibility result:

- Signature unchanged.
- Return type remains `int`.
- Equal fields still have equal hashes.
- Unequal fields may now share hashes when they share a `creation_counter` but differ by model. This is allowed by Python and explicitly supported by the issue text.

Public evidence conflict:

- `repo/tests/model_fields/tests.py` contains legacy assertions that unequal abstract-inherited fields must have unequal hashes.
- Those assertions are marked SUSPECT in `fvk/FINDINGS.md` because they conflict with I-002. The production code should not preserve a hash uniqueness guarantee that the public issue rejects.

## Domain Assumptions

The proof domain is Django-managed field lifecycle code: fields are constructed by `Field.__init__()` and then may be attached to model classes by `contribute_to_class()`. Direct user mutation of `creation_counter` after a field has been used as a key is outside the public issue's stated behavior and is recorded as an underspecified edge case in `fvk/FINDINGS.md`.
