# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, or `kprove` were run.

## Claims Proved

The proof covers the storage-specific behavior of `FileField.__init__()` and `FileField.deconstruct()`:

- Callable storage providers are evaluated once during construction for runtime state and validation.
- The original callable provider is preserved in `_storage_callable`.
- Deconstruction serializes the preserved callable and does not call it.
- Callable providers returning `default_storage` still serialize as the callable.
- Non-callable explicit storage and default storage behavior are unchanged.
- `ImageField` inherits the corrected storage deconstruction through `super().deconstruct()`.

## Symbolic Execution Sketch

Constructor callable path:

1. Start with `storage=C`, where `C()` returns valid storage `S`.
2. `self.storage = storage or default_storage` stores `C` under the ordinary callable-provider domain.
3. `callable(self.storage)` is true.
4. `self._storage_callable = self.storage` records `C`.
5. `self.storage = self.storage()` evaluates `C` once and stores `S`.
6. `isinstance(self.storage, Storage)` succeeds.
7. Resulting field state is `field(storage=S, storage_callable=C)`.

Deconstruct callable path:

1. Start with a field state containing `_storage_callable=C` and runtime storage `S`.
2. `super().deconstruct()` produces base `(name, path, args, kwargs)`.
3. Default `max_length` is removed if present.
4. `kwargs["upload_to"] = self.upload_to` preserves existing upload behavior.
5. `hasattr(self, "_storage_callable")` is true.
6. `kwargs["storage"] = self._storage_callable` writes `C`.
7. No rule in the deconstruct path invokes `C`; the callable call count is unchanged.

Callable returning default storage:

1. Start with `_storage_callable=C` and runtime storage `default_storage`.
2. The callable branch is selected before the non-callable `elif self.storage is not default_storage` branch.
3. Deconstruction writes `kwargs["storage"] = C`.

Non-callable frame paths:

1. If no `_storage_callable` exists and `self.storage is not default_storage`, deconstruction writes the runtime storage instance.
2. If no `_storage_callable` exists and `self.storage is default_storage`, neither storage branch writes a kwarg.

Invalid callable result:

1. Start with callable `C()` returning `invalid`.
2. Constructor records `_storage_callable=C` and evaluates `C`.
3. `isinstance(self.storage, Storage)` fails.
4. The existing `TypeError` branch is reached; no valid field exists to deconstruct.

ImageField:

1. `ImageField.deconstruct()` calls `FileField.deconstruct()`.
2. The storage kwargs are already correct when image-specific `width_field` and `height_field` kwargs are added.

## Proof Obligations

Discharged obligations are listed in `fvk/PROOF_OBLIGATIONS.md`:

- PO-1: constructor preserves original callable.
- PO-2: deconstruct serializes preserved callable without calling it.
- PO-3: callable returning default storage is not omitted.
- PO-4: non-callable explicit storage frame.
- PO-5: default storage omission frame.
- PO-6: invalid callable result still raises `TypeError`.
- PO-7: `ImageField` delegation.

## Machine-Check Commands Not Run

The K artifacts are:

- `fvk/mini-python-filefield.k`
- `fvk/filefield-storage-spec.k`

Expected commands for a later environment with K installed:

```sh
cd fvk
kompile mini-python-filefield.k --backend haskell
kast --backend haskell filefield-storage-spec.k
kprove filefield-storage-spec.k
```

Expected machine-check result: `#Top` for all claims. This expectation is reasoned from the symbolic execution above and is not an observed tool result.

## Test Guidance

No tests were run or modified. If the K proof is later machine-checked, unit tests that only assert callable-storage deconstruction returns the callable would be subsumed by PO-2 and PO-3. Keep integration tests for migration serialization, storage runtime behavior, `ImageField`, and invalid callable error behavior because this proof models only the storage-specific unit logic and not the full Django migration machinery.

## Residual Risk

The proof is partial correctness over an abstract mini semantics. Trusted bases are:

- adequacy of the mini model for the storage identity/call-count behavior;
- correctness of the superclass `Field.deconstruct()` frame abstraction;
- K reachability-logic metatheory and the future `kprove` run.

No termination proof is needed because the modeled code has no loop or recursion.
