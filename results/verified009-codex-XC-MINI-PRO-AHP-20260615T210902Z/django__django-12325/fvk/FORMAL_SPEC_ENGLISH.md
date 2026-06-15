# Formal Spec English

The K model abstracts the relevant part of `ModelBase.__new__()` to a function `collect(fields)` over a list of declared fields. Each field is represented as `field(Name, RelatedModelKey, IsOneToOne, ParentLink)`. The result is a map from related model key to the field name selected as a declared inheritance parent link.

C1. For fields `[field(1, Parent, true, true), field(2, Parent, true, false)]`, `collect()` returns `{Parent: 1}`. An ordinary one-to-one field declared after the explicit parent link does not replace it.

C2. For fields `[field(2, Parent, true, false), field(1, Parent, true, true)]`, `collect()` returns `{Parent: 1}`. An ordinary one-to-one field declared before the explicit parent link does not prevent the explicit parent link from being selected.

C3. For fields `[field(2, Parent, true, false)]`, `collect()` returns the empty map. A standalone ordinary one-to-one field to a parent model is not a declared parent link, so the parent-link collection step leaves auto-creation available.

C4. For fields `[field(3, Parent, false, true)]`, `collect()` returns the empty map. Non-`OneToOneField` declarations do not affect parent-link collection.

Frame condition F1. The model only changes the parent-link selection relation. Later `_meta.parents` population, automatic parent pointer creation, primary-key promotion, and clash checks are outside the K fragment but are covered as proof obligations in `PROOF_OBLIGATIONS.md`.
