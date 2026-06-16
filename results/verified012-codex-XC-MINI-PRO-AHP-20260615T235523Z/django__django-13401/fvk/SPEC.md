# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K commands were
run.

## Scope

Target source: `repo/django/db/models/fields/__init__.py`, specifically
`Field.__eq__()`, `Field.__lt__()`, `Field.__hash__()`, and the helper used by
`__lt__`.

The formal model abstracts a Django field as:

- `creation_counter`: the declaration-order counter copied by abstract
  inheritance.
- `model`: the owner assigned by `contribute_to_class()`, represented by a
  model label and identity component, or absent for unattached fields.

## Intended Contract

1. Two `Field` instances compare equal only when they have the same
   `creation_counter` and the same owner model.
2. Same-counter fields copied from an abstract base onto different concrete
   models compare unequal.
3. Hashing is consistent with equality by using the same identity tuple.
4. Ordering compares `creation_counter` first. The model tie-breaker is used
   only when counters are equal.
5. Public comparison method signatures and `NotImplemented` behavior for
   non-`Field` operands remain unchanged.

## Public Intent Ledger

The standalone ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1/E4 encode the main owner-sensitive equality obligation.
- E3 encodes the set-cardinality obligation from the issue reproduction.
- E5 encodes the hash/order coherence obligation.
- E6/E8 encode the creation-counter-primary ordering obligation.
- E7 records the implementation fact that abstract inheritance preserves
  counters and assigns the copied field's model before `_meta.add_field()`.

## Formal Core

Formal semantics fragment: `fvk/mini-field-comparison.k`.

Formal claims: `fvk/field-comparison-spec.k`.

The semantics is intentionally small. It models only the observable properties
needed for this issue: equality, hash key, less-than, set retention, and the
model sort key used for same-counter ordering.

## Adequacy

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases the formal claims. `fvk/SPEC_AUDIT.md`
checks those paraphrases against `fvk/INTENT_SPEC.md`. The audit passes for the
reported issue and records one scoped default assumption: ordering of two
different model objects with the same label is under-specified by public intent,
so V1's identity component is treated only as a same-label tie-breaker.
