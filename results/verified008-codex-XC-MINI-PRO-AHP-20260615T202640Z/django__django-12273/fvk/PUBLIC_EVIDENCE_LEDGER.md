# Public Evidence Ledger

## E1: Issue title

- Source: `benchmark/PROBLEM.md`
- Evidence: "Resetting primary key for a child model doesn't work."
- Obligation: child-model primary-key reset must have a useful copy semantics
  for multi-table inheritance.
- Status: encoded in `SPEC.md` and `model-pk-spec.k`.

## E2: Issue symptom

- Source: `benchmark/PROBLEM.md`
- Evidence: "setting the primary key to None does not work (so that the
  existing object is overwritten on save())."
- Obligation: after reset, `save()` must not update the old parent row.
- Status: encoded as the save-path consequence proof obligation.

## E3: `pk` as the public alias

- Source: public hints in `benchmark/PROBLEM.md`
- Evidence: "`self.pk = None` ... will be alias for `self.item_ptr` for
  `Derived` instances and `self.uid` for `Item` instances"; then "Can we
  consider that `self.pk = None` does not work too, as a bug?"
- Obligation: the repaired behavior is specifically for the `pk` property
  setter, not arbitrary direct assignment to every inherited concrete PK field.
- Status: encoded in `SPEC.md`, `FINDINGS.md` F4, and `PROOF_OBLIGATIONS.md`
  PO1.

## E4: Multi-level inheritance

- Source: public hints in `benchmark/PROBLEM.md`
- Evidence: "In my real code I may have several levels of inheritance (not just
  Item and Derived)."
- Obligation: the reset must walk a chain of parent-link primary keys, not only
  set one direct parent attribute.
- Status: encoded in `SPEC.md` and proof obligation PO1.

## E5: Avoid all-parent reset

- Source: public hints in `benchmark/PROBLEM.md`
- Evidence: "The patch doesn't seem to work for child models that inherit from
  multiple models. It also created some other test failures."
- Obligation: a fix must be narrower than assigning through every entry in
  `_meta.parents`.
- Status: encoded in `FINDINGS.md` F3 and compatibility obligation PO5.

## E6: Django copy docs

- Source: `repo/docs/topics/db/queries.txt`
- Evidence: copying a simple model uses `blog.pk = None`; current inheritance
  docs say "you have to set both `pk` and `id` to None".
- Obligation: `pk = None` is established copy idiom; the bug is that MTI needs
  the parent PK cleared too.
- Status: supports PO1 and PO4.

## E7: Implementation facts

- Source: `repo/django/db/models/base.py`
- Evidence: `_save_table()` tries an update when `pk_val` is not `None`;
  `_save_parents()` saves parents before the child and synchronizes parent-link
  fields from parent PK values.
- Obligation: the setter must clear every PK value that those save routines
  consult along the active primary-key parent-link chain.
- Status: encoded in PO4 as implementation-derived support.
