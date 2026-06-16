# PROOF

Status: constructed, not machine-checked.

## Scope

This proof covers the storage-kwarg decision made by
`FileField.deconstruct()` after `FileField.__init__()` has normalized direct
and callable storage arguments. It does not cover file I/O, storage backend
methods, upload path generation, migration writer formatting, or test
execution.

## Claims proved by construction

- `DEFAULT-IMPLICIT`: no explicit storage argument deconstructs with storage
  omitted.
- `DIRECT-DEFAULT`: direct `default_storage` deconstructs with storage omitted.
- `DIRECT-OTHER`: direct non-default storage deconstructs with that storage
  object included.
- `CALLABLE-DEFAULT`: callable storage returning `default_storage` deconstructs
  with the original callable included.
- `CALLABLE-OTHER`: callable storage returning non-default storage deconstructs
  with the original callable included.

## Proof sketch

The finite semantics in `mini-python-filefield.k` models the relevant state as
`field(evaluatedStorage, maybeCallable)`. `FileField.__init__()` corresponds to
rules that set `maybeCallable` to `someCallable(C)` exactly when the original
storage argument is callable; otherwise it is `noCallable`.

V1 `FileField.deconstruct()` corresponds to selecting
`getattr(self, "_storage_callable", self.storage)` before the default
comparison. In the model, that yields:

- `serializedCallable(C)` whenever `maybeCallable = someCallable(C)`;
- `serializedStorage(S)` whenever `maybeCallable = noCallable`.

The default omission rule is then applied to the selected value, not to the
evaluated runtime storage. Therefore the callable-default case cannot be
mistaken for implicit default storage: its selected value is the callable, not
`defaultStorage`.

Each claim in `filefield-deconstruct-spec.k` is a one-step finite rewrite in
the model:

- `initThenDeconstruct(noStorageArg)` rewrites to `omitStorage`.
- `initThenDeconstruct(direct(defaultStorage))` rewrites to `omitStorage`.
- `initThenDeconstruct(direct(otherStorage))` rewrites to
  `includeStorage(serializedStorage(otherStorage))`.
- `initThenDeconstruct(callable(getDefaultStorage, defaultStorage))` rewrites
  to `includeStorage(serializedCallable(getDefaultStorage))`.
- `initThenDeconstruct(callable(getOtherStorage, otherStorage))` rewrites to
  `includeStorage(serializedCallable(getOtherStorage))`.

There are no loops or recursive calls, so no circularity claim is required.
The proof is partial correctness over the finite deconstruction model and has
no termination obligation beyond the finite rewrite sequence.

## Adequacy gate

`FORMAL_SPEC_ENGLISH.md` paraphrases every claim. `SPEC_AUDIT.md` compares
those paraphrases with `INTENT_SPEC.md` and marks all as pass. The key issue
case is `CALLABLE-DEFAULT`, which maps directly to the issue's expected
`storage=<callable>` migration kwarg when the callable returns
`default_storage`.

## Proof-derived findings

No proof-derived code bug remains in the audited scope. Findings FVK-F2 through
FVK-F4 confirm that V1 discharges the callable-default issue and preserves the
surrounding direct/callable cases. Finding FVK-F5 records why no V2 source edit
is justified.

## Test guidance

No tests were modified or run. Existing tests that assert callable storage
deconstruction to the original callable are covered by the `CALLABLE-OTHER`
claim in this finite model. A hidden or future test for callable storage
returning `default_storage` would be covered by `CALLABLE-DEFAULT`.

Because this proof is constructed and not machine-checked, no test removal is
recommended.

## Machine-check commands not run

From the `fvk/` directory, the commands to check later would be:

```sh
kompile mini-python-filefield.k --backend haskell
kast --backend haskell filefield-deconstruct-spec.k
kprove filefield-deconstruct-spec.k
```

Expected result if the finite K artifacts are accepted by the toolchain:
`kprove` returns `#Top` for all five claims.
