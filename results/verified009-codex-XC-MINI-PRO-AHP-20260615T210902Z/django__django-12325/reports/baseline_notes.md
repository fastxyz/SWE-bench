# Baseline Notes

## Root cause

`ModelBase.__new__()` builds a `parent_links` dictionary for multi-table inheritance by scanning every local `OneToOneField` declared on the new model and abstract bases. The dictionary is keyed only by the related model, so multiple one-to-one fields pointing at the same concrete parent overwrite each other.

That means an ordinary relation such as `origin = OneToOneField(Document, related_name='picking')` can replace the explicit `document_ptr = OneToOneField(Document, parent_link=True)` entry if it appears later in field order. `_meta.parents` is then populated with the ordinary field. During `_prepare()`, Django promotes that field as the inherited primary key and raises `ImproperlyConfigured` because `origin.remote_field.parent_link` is false.

The same root cause also affects a child model with a clearly separate one-to-one relation to its parent model: if the field has its own `related_name`, it should remain an ordinary relation and Django should create the normal inherited parent pointer.

## Changed files

`repo/django/db/models/base.py`

Changed the parent-link collection loop so an explicit `parent_link=True` field always claims the related parent model key. Ordinary one-to-one fields with a declared `related_name` are no longer stored as parent-link candidates, which lets Django auto-create the normal parent pointer for those separate relations. Ordinary one-to-one fields without a declared reverse name are still retained as candidates only when no explicit parent link has already been found, preserving the existing ambiguous-configuration path that raises the `Add parent_link=True` message.

`reports/baseline_notes.md`

Added this report with the root cause, changed-file rationale, assumptions, and rejected alternatives.

## Assumptions and alternatives

I assumed that `parent_link=True` is the authoritative signal for a user-declared inheritance link, and that field declaration order should not affect which one-to-one relation becomes `_meta.parents[Parent]`.

I also assumed that a one-to-one field to the parent with an explicit `related_name` is intended to be an ordinary relation, not a custom inheritance pointer. This matches the reported `origin` and `some_unrelated_document` examples, both of which declare separate reverse names.

I considered filtering `parent_links` to include only fields with `remote_field.parent_link`. That is the cleanest interpretation of the flag, but it would also remove the existing early `ImproperlyConfigured` path for a bare `OneToOneField` to the parent that looks like an attempted custom parent pointer. I kept that validation behavior for fields without a declared reverse name while still fixing the ordering bug and the separate-relation case described in the issue.
