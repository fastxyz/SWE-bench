# FVK Specification

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 edit to `Model._set_pk_val()` in
`repo/django/db/models/base.py`. The modeled unit is the public `pk` property
setter for Django model instances, plus the static consequence that Django's
parent save path observes the primary-key values written by that setter.

The formal core is in:

- `fvk/mini-django-pk.k`
- `fvk/model-pk-spec.k`

The adequacy core is in:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

## Public Intent Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | Issue title | "Resetting primary key for a child model doesn't work." | Child-model PK reset must work for MTI copying. | Encoded. |
| E2 | Issue symptom | Existing object is overwritten on `save()`. | Reset must prevent old parent row update. | Encoded. |
| E3 | Public hints | "`self.pk = None` ... alias for `self.item_ptr` ... and `self.uid`." | Repair the `pk` setter. | Encoded. |
| E4 | Public hints | "several levels of inheritance" | Walk a finite parent-link PK chain. | Encoded. |
| E5 | Public hints | All-parent patch failed for multiple models and other tests. | Do not reset unrelated parent links. | Encoded. |
| E6 | Django docs | Simple copy idiom is `pk = None`; inheritance docs require `pk` and `id`. | `pk` reset must clear parent PK too. | Encoded. |
| E7 | Source | `_save_table()` updates when `pk_val` is set. | Clear every PK value consulted by save. | Encoded. |

The full evidence ledger is mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

## Intended Contract

For any Django model instance whose `_meta.pk` field starts a finite acyclic
primary-key parent-link chain:

1. Assigning `instance.pk = value` writes `value` to every field attname in that
   chain.
2. Assigning `instance.pk = value` does not write to parent links outside that
   active primary-key chain.
3. If the chain contains only a normal local primary key, the behavior is the
   original single-attribute assignment.
4. If `value is None`, a following ordinary `save()` must not update an old
   parent table row through a stale primary-key value in that chain.

## Formal Model

The mini-K model abstracts the relevant Django state as:

- `<attrs>`: a map from field ids to instance attribute values.
- `<next>`: a map from a field id to `parent(next_id)` if the field is a
  parent-link primary key targeting another parent primary-key field, or
  `noParent` if the chain stops.
- `setPk(F, V)`: the operational analogue of V1's `_set_pk_val()` loop.

The model deliberately omits unrelated ORM behavior, database I/O, managers,
signals, and descriptors except for the frame condition that field ids outside
the active chain are not changed by the setter.

## Adequacy

The abstraction preserves the property that matters for the reported bug:
whether every primary-key value consulted by `_save_parents()` and
`_save_table()` along the active MTI identity chain is cleared. It distinguishes
the failing pre-fix state (`child_ptr = None`, `parent_pk = old`) from the
passing state (`child_ptr = None`, `parent_pk = None`).

The model does not claim to verify arbitrary direct assignment to inherited
parent PK fields such as `derived.uid = None`; that is recorded as residual
ambiguity in `fvk/FINDINGS.md` F4.
