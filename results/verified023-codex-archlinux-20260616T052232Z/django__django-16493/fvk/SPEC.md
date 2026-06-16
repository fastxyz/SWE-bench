# SPEC

Status: constructed for audit; not machine-checked.

## Unit under audit

`repo/django/db/models/fields/files.py`, specifically
`FileField.__init__()` storage handling and `FileField.deconstruct()` storage
kwarg selection.

## Observable

The observable is the `storage` entry in the kwargs returned by
`FileField.deconstruct()`:

- omitted for implicit/default storage;
- present with a direct non-default storage object;
- present with the original callable for callable storage arguments, regardless
  of whether the callable evaluates to default or non-default storage.

## Public intent ledger

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The critical entries are:

- E1-E4: the issue states that callable storage returning `default_storage` is
  incorrectly omitted because the old comparison used evaluated `self.storage`.
- E5-E6: the public hint says `_storage_callable` should be used by
  deconstruction and recommends using
  `getattr(self, "_storage_callable", self.storage)` in both lines.
- E7: Django docs make both direct storage objects and callable storage
  providers public `FileField.storage` inputs.
- E8: Django deconstruction docs require kwargs that can recreate field state.
- E9: public tests require callable storage deconstruction to return the
  original callable, not the evaluated value.

## Preconditions and domain

The storage argument is one of:

- absent/`None`, represented as `noStorageArg`;
- direct `default_storage`, represented as `direct(defaultStorage)`;
- direct non-default storage, represented as `direct(otherStorage)`;
- callable returning `default_storage`, represented as
  `callable(getDefaultStorage, defaultStorage)`;
- callable returning non-default storage, represented as
  `callable(getOtherStorage, otherStorage)`.

The formal model assumes callable storage providers are distinguishable from
storage objects. This matches the public docs phrasing "A storage object, or a
callable which returns a storage object."

## Postconditions

P1. `noStorageArg` deconstructs to `omitStorage`.

P2. `direct(defaultStorage)` deconstructs to `omitStorage`.

P3. `direct(otherStorage)` deconstructs to
`includeStorage(serializedStorage(otherStorage))`.

P4. `callable(getDefaultStorage, defaultStorage)` deconstructs to
`includeStorage(serializedCallable(getDefaultStorage))`.

P5. `callable(getOtherStorage, otherStorage)` deconstructs to
`includeStorage(serializedCallable(getOtherStorage))`.

## K artifacts

- Semantics: `fvk/mini-python-filefield.k`.
- Claims: `fvk/filefield-deconstruct-spec.k`.

The emitted commands to machine-check later are recorded in `fvk/PROOF.md`.
They were not executed in this session.
