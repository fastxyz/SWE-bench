# Spec Audit

Status: constructed, not machine-checked.

| Claim | Audit Result | Rationale |
|---|---|---|
| C1 Stable Unique Helper | pass | Public intent requires no duplicate locations. Preserving first-occurrence order is a conservative frame condition over the existing ordered traversal. |
| C2 Catalog Message Location Construction | pass | The public hint explicitly says `Catalog.__iter__()` must normalize source paths with `relpath(..., cwd)` because exact de-duplication is insufficient. |
| C3 Message Location Storage | pass | The issue points at `Message.__init__()` and suggests de-duplicating `locations`; V1 does this with stable order rather than unordered `set()` conversion. |
| C4 Rendered Location Uniqueness | pass | The issue examples are duplicate rendered `#: path:line` comments, so the formal observable is rendered path plus line. |
| C5 Rendering Preservation | pass | The issue asks to remove duplicates, not change retained location spelling. This follows from the relpath composition lemma in PO3. |
| C6 Frame Conditions | pass | No public intent asks to change message IDs, UUIDs, template escaping, catalog grouping, or message sorting. |
| Babel wrapping/sorting | pass as out of scope | The issue text mentions these as further observations about Babel and PO output sorting, but the duplicate `Message.locations` bug is fixed in Sphinx's gettext builder path. |
| UUID de-duplication | ambiguous/out of scope | `gettext_uuid` output is not the reported symptom. No code change is justified without stronger public intent. |
