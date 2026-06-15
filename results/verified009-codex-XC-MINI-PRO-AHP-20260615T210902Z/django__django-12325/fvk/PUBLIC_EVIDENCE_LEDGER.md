# Public Evidence Ledger

| ID | Source | Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "`document_ptr = OneToOneField(... parent_link=True ...)` followed by `origin = OneToOneField(...)` produces `ImproperlyConfigured`" | The explicit parent link must not be displaced by `origin`. | Encoded in `SPEC.md`, K claims C1/C2. |
| E2 | prompt | "First issue is that order seems to matter? ... It shouldn't" | Selection must be independent of ordinary-field order relative to the explicit parent link. | Encoded in K claims C1/C2. |
| E3 | prompt | "we have explicit parent_link marker" | `remote_field.parent_link` is the intended discriminator. | Encoded in V2 source and K semantics. |
| E4 | prompt | "`some_unrelated_document = OneToOneField(Document, related_name='something', ...)` Produces the same error" | Ordinary one-to-one fields to a parent are in-domain and must not become parent links. | Encoded in K claim C3. |
| E5 | docs | "`parent_link=True` ... indicates that this field should be used as the link back to the parent class" | Only explicitly marked fields are declared inheritance links. | Encoded in V2 source and K semantics. |
| E6 | docs | "Django will automatically create a OneToOneField linking your child class back to any non-abstract parent models" | No declared parent-link entry should allow auto-creation. | Encoded in K claim C3 and proof obligation PO4. |
| E7 | public-test | `test_missing_parent_link` expects the same `Add parent_link=True` class-construction error for `parent = OneToOneField(Place, CASCADE)`. | Legacy behavior conflict. | Marked SUSPECT in `FINDINGS.md`; not used as a veto. |
