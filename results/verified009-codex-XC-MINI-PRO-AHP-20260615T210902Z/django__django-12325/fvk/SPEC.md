# SPEC

Status: constructed, not machine-checked. K commands are recorded in `PROOF.md` and were not executed.

## Target

Audit and repair the parent-link discovery loop in `repo/django/db/models/base.py` within `ModelBase.__new__()`.

The observable under specification is the `parent_links` map produced from local fields before concrete parent handling. This map decides whether a concrete parent uses a declared parent-link field or falls through to Django's existing auto-created `<parent>_ptr` field path.

## Intent Ledger

See `PUBLIC_EVIDENCE_LEDGER.md` for the full ledger.

Critical obligations:

- E1/E2/E3: An explicit `parent_link=True` field must be selected regardless of ordinary `OneToOneField` order.
- E4/E5: An ordinary `OneToOneField` to the parent is not a parent link merely because it points to the parent.
- E6: If no explicit parent link is present, the collection map must leave the parent absent so the existing auto-created pointer branch can run.
- E7: A public in-repo test expecting the old `Add parent_link=True` error for a bare ordinary one-to-one field is SUSPECT because it encodes behavior the issue reports as the bug.

## Domain Model

The mini-K model abstracts each local field as:

`field(Name, RelatedModelKey, IsOneToOne, ParentLink)`

The modeled function is:

`collect(fields) -> parentLinksMap`

The intended selection rule is:

1. Scan the fields in declaration order, matching Django's loop over `base._meta.local_fields`.
2. If a field is a `OneToOneField` and `field.remote_field.parent_link` is true, set `parentLinksMap[related_model_key] = field`.
3. Otherwise, leave `parentLinksMap` unchanged.

This intentionally excludes ordinary `OneToOneField`s from the parent-link map. Later Django code can then auto-create the inherited pointer if no explicit entry exists.

## Required Claims

C1. Explicit parent link followed by ordinary one-to-one to the same parent selects the explicit parent link.

C2. Ordinary one-to-one followed by explicit parent link to the same parent selects the explicit parent link.

C3. A standalone ordinary one-to-one to the parent contributes no declared parent-link entry.

C4. Non-one-to-one fields contribute no declared parent-link entry.

The K claims are in `modelbase-parent-links-spec.k`; their English paraphrase and adequacy audit are in `FORMAL_SPEC_ENGLISH.md` and `SPEC_AUDIT.md`.

## Out Of Scope

This FVK pass does not model all of Django class construction, descriptors, app registry resolution, metaclass side effects, or exception formatting. Those are unnecessary for the defect axis and are covered by source-level proof obligations where relevant.
