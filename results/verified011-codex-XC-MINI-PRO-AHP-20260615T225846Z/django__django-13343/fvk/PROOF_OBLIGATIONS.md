# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Constructor Preserves Original Callable

For any callable storage provider `C` returning valid storage `S`, after `FileField.__init__(storage=C)`:

- `field.storage is S`;
- `field._storage_callable is C`;
- `C` has been evaluated once for runtime validation/state.

Evidence: `self._storage_callable = self.storage` is executed before `self.storage = self.storage()`.

Findings: F-001.

Status: discharged by symbolic execution of the callable constructor branch.

## PO-2: Deconstruct Serializes Preserved Callable Without Calling It

For any field with `_storage_callable = C`, `FileField.deconstruct()` returns kwargs with `storage=C`, not the evaluated runtime storage, and does not evaluate `C`.

Evidence: `if hasattr(self, '_storage_callable'): kwargs['storage'] = self._storage_callable`.

Findings: F-001, F-002.

Status: discharged by symbolic execution of the first storage branch in `deconstruct()`.

## PO-3: Callable Returning Default Storage Is Not Omitted

For any callable `C` returning `default_storage`, `FileField.deconstruct()` still returns kwargs with `storage=C`.

Evidence: the callable branch is checked before `self.storage is not default_storage`.

Findings: F-002.

Status: discharged as a corollary of PO-2.

## PO-4: Non-callable Explicit Storage Frame

For any field with no `_storage_callable` and `self.storage is not default_storage`, `FileField.deconstruct()` returns kwargs with `storage=self.storage`.

Evidence: `elif self.storage is not default_storage: kwargs['storage'] = self.storage`.

Findings: F-003.

Status: discharged by symbolic execution of the non-callable non-default branch.

## PO-5: Default Storage Omission Frame

For any field with no `_storage_callable` and `self.storage is default_storage`, `FileField.deconstruct()` omits `storage` from kwargs.

Evidence: no storage assignment executes after the `elif` condition fails.

Findings: F-004.

Status: discharged by symbolic execution of the default-storage branch.

## PO-6: Invalid Callable Result Still Raises TypeError

For any callable `C` returning a non-`Storage` value, construction raises the existing `TypeError` and does not create a valid field state for deconstruction.

Evidence: the `isinstance(self.storage, Storage)` check remains immediately after callable evaluation.

Findings: F-001.

Status: discharged by symbolic execution of the invalid callable constructor branch.

## PO-7: ImageField Delegation

For `ImageField(storage=C)`, the storage part of deconstruction obeys PO-2 before image-specific kwargs are added.

Evidence: `ImageField.deconstruct()` calls `name, path, args, kwargs = super().deconstruct()`.

Findings: F-005.

Status: discharged by call-chain inspection and the `FileField` proof obligations.
