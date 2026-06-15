# FVK Proof Obligations

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## PO1: Lazy string references preserve app-label case

For every normalized lazy relation string `A.M` reaching `ForeignObject.deconstruct()`, the serialized `kwargs["to"]` must have app label `A`, byte-for-byte unchanged.

Proven by source inspection and K claim: `LAZY-REF-PRESERVES-APP-LABEL`.

Linked findings: F1.

## PO2: Lazy string references lowercase only the model component

For every normalized lazy relation string `A.M`, the serialized model component must be `lower(M)`.

Proven by source inspection and K claim: `LAZY-REF-PRESERVES-APP-LABEL`.

Linked findings: F1.

## PO3: Non-string model references keep existing label_lower behavior

For every concrete model reference with `_meta.app_label == A` and `_meta.model_name == m`, the serialized value must be `A.m`.

Proven by source inspection and K claim: `CONCRETE-REF-LABEL-LOWER`.

Linked findings: F2, F3.

## PO4: The proof localizes the reported failure path

The value responsible for the reported lazy-reference error is created by field deconstruction during clone/state rendering, not by later migration operation reference-reduction helpers.

Source path:

```text
ModelState.from_model()
  -> field.clone()
  -> Field.clone()
  -> ForeignObject.deconstruct()
  -> ModelState.render()
  -> StateApps._check_lazy_references()
```

Proven by source inspection of `state.py`, `fields/__init__.py`, `related.py`, and `model_checks.py`.

Linked findings: F1, F4.

## PO5: Wrapping and return-shape frame condition

The fix must not change the public `deconstruct()` tuple shape, the public field constructors, or the swappable wrapper protocol. If `SettingsReference` is applied, it must wrap the already-correct `to` value.

Proven by source inspection. V1 changes only the local string used for `kwargs["to"]`.

Linked findings: F3.

## PO6: Domain boundary for relation strings

The formal string-branch claim ranges over normalized `app_label.ModelName` strings. This domain is independently justified by `make_model_tuple()` and the lazy operation key format. Invalid strings, bare relative strings, and `self` are not the reported migration-state failure; they are resolved earlier on the normal model-construction path or rejected by existing validation.

Proven by source inspection of `resolve_relation()`, `lazy_related_operation()`, and `make_model_tuple()`.

Linked findings: F4.

## Verification status

All obligations are discharged by V1 under the stated domain and frame conditions. No additional source edit is required.

