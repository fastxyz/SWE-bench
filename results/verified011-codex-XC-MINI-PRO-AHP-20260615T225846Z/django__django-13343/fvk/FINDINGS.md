# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## F-001: Callable storage was frozen into migrations

Classification: code bug, resolved.

Input: `FileField(storage=C)` where callable `C` returns storage instance `S`.

Observed in the pre-fix implementation: construction replaced `self.storage` with `S`; `deconstruct()` serialized `kwargs["storage"] = S`.

Expected from public intent: `deconstruct()` serializes `kwargs["storage"] = C` and does not call `C` during deconstruction.

Resolution: `FileField.__init__()` preserves the original callable in `_storage_callable`; `FileField.deconstruct()` serializes `_storage_callable` when present.

Proof obligations: PO-1, PO-2.

## F-002: Callable returning default storage must still be serialized as callable

Classification: corner case, resolved.

Input: `FileField(storage=C)` where callable `C` returns `default_storage`.

Risk: If deconstruction only compared the evaluated runtime storage to `default_storage`, it could omit the explicit callable and lose the runtime selection hook.

Expected from public intent: `kwargs["storage"] = C`, because the supplied callable is the migration-relevant value.

Resolution: `deconstruct()` now branches first on `hasattr(self, "_storage_callable")` and unconditionally serializes the preserved callable on that path.

Proof obligations: PO-2, PO-3.

## F-003: Non-callable storage behavior must be preserved

Classification: frame condition, resolved.

Input: `FileField(storage=S)` for explicit non-default storage instance `S`.

Expected from public intent and existing API behavior: `deconstruct()` serializes `kwargs["storage"] = S`.

Resolution: the non-callable branch remains `elif self.storage is not default_storage: kwargs["storage"] = self.storage`.

Proof obligation: PO-4.

## F-004: Default storage behavior must be preserved

Classification: frame condition, resolved.

Input: `FileField()` or effective storage `default_storage` with no callable provider.

Expected from existing API behavior: `deconstruct()` omits the `storage` kwarg.

Resolution: the default-storage branch still omits `storage` when no `_storage_callable` exists.

Proof obligation: PO-5.

## F-005: ImageField inherits the storage fix

Classification: compatibility check, resolved.

Input: `ImageField(storage=C)`.

Expected from public intent: the callable-storage deconstruction behavior applies to `ImageField`.

Resolution: `ImageField.deconstruct()` calls `super().deconstruct()`, so the `FileField` storage logic is used before adding image-specific kwargs.

Proof obligation: PO-7.

## F-006: Machine-check and execution are intentionally absent

Classification: verification gap, not a code bug.

Input: all proof obligations.

Observed: this environment forbids running tests, Python, `kompile`, or `kprove`.

Expected from the task: write commands and reason about expected outcomes instead of executing them.

Resolution: `fvk/PROOF.md` records exact commands and labels the proof constructed, not machine-checked. Test removal is not recommended unless those commands later return `#Top`.
