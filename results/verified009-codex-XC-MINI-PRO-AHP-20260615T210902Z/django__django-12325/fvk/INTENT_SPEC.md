# Intent Spec

Status: constructed from public issue text, public Django docs in `repo/docs/`, and source names/comments. Current implementation behavior is treated only as an observation to audit.

## Required Behaviors

I1. `parent_link=True` is the authoritative marker for a user-declared multi-table-inheritance parent link.

Evidence: `benchmark/PROBLEM.md` says "we have explicit parent_link marker"; `repo/docs/ref/models/fields.txt` says `parent_link=True` indicates the field is the link back to the parent class.

I2. Field declaration order must not allow an ordinary `OneToOneField` to the same parent model to replace an explicit `parent_link=True` field in `_meta.parents`.

Evidence: `benchmark/PROBLEM.md` reports that declaring `document_ptr` before `origin` fails while the reverse order works, then says order "shouldn't" matter.

I3. An ordinary `OneToOneField` to a parent model is not an inheritance link merely because it points at that parent model.

Evidence: `benchmark/PROBLEM.md` gives `some_unrelated_document = OneToOneField(Document, related_name='something', ...)` as the same bug; `repo/docs/topics/db/models.txt` says Django automatically creates the child-parent `OneToOneField` unless the user creates one and sets `parent_link=True`.

I4. If a child class has no declared `parent_link=True` field to a concrete parent, the parent-link collection step should leave no declared entry for that parent so the existing auto-created pointer path can run.

Evidence: `repo/docs/topics/db/models.txt` says Django automatically creates the child-to-parent `OneToOneField`.

I5. Existing behavior that raises `ImproperlyConfigured: Add parent_link=True ...` solely because an ordinary `OneToOneField` points at a parent model is suspect when applied to the reported ordinary-field examples.

Evidence: the issue reports that error as the bug symptom.
