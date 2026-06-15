# FVK Findings

Status: constructed, not machine-checked.

## Resolved Findings

F1. False `admin.E108` for fields whose model class descriptor is inaccessible.

- Input shape: `callable(item) == false`, no `ModelAdmin` attribute, metadata
  lookup resolves a normal field, and model class attribute access would raise
  `AttributeError`.
- Observed before V1: `E108`, because the code checked `hasattr(obj.model,
  item)` before trying `_meta.get_field(item)`.
- Expected: `OK`, because a field found in model metadata is a valid
  `list_display` item unless it is a `ManyToManyField`.
- Proof obligations: PO2, PO7.
- Status: resolved by V1 and preserved in V2.

F2. V1 still allowed a `ModelAdmin` attribute to mask a same-named model field
for validation.

- Input shape: `callable(item) == false`, metadata lookup resolves a
  `ManyToManyField`, and `hasattr(obj, item) == true` because the
  `ModelAdmin` defines a same-named attribute or method.
- Observed in V1: `OK`, because V1 returned immediately for
  `hasattr(obj, item)` before field metadata lookup.
- Expected: `E109`, because the public admin docs and runtime `lookup_field()`
  behavior put model field resolution before `ModelAdmin` attribute fallback.
- Proof obligations: PO3, PO9.
- Status: resolved in V2 by moving metadata lookup before `hasattr(obj, item)`.

F3. Missed `ManyToManyField` rejection for model attribute fallback.

- Input shape: metadata lookup raises `FieldDoesNotExist`,
  `hasattr(obj, item) == false`, and model attribute fallback resolves a
  `ManyToManyField`.
- Observed before V1: `OK` in the branch where `hasattr(obj.model, item)` was
  true but `_meta.get_field()` raised, because the code returned success before
  checking the resolved object.
- Expected: `E109`, per the issue's truth table and Django's documented
  `ManyToManyField` exclusion.
- Proof obligations: PO6.
- Status: resolved by V1 and preserved in V2.

## Proof-Derived Findings

F4. No loop or recursion circularity is required.

- Evidence: the target helper is a finite conditional decision procedure.
- Classification: proof simplification, not a code bug.
- Recommended action: use complete case-split claims instead of loop
  invariants. This is reflected in `list-display-check-spec.k`.

F5. The proof is constructed but not machine-checked.

- Evidence: task constraints forbid running K tooling.
- Classification: proof status caveat.
- Recommended action: run the emitted `kompile`, `kast`, and `kprove` commands
  in an environment with K installed before treating any test as removable.

## Open Findings

None for the audited contract.

