# Public Evidence Ledger

Status: constructed for audit; not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | Problem statement | "`ForeignKey.validate()` should validate using the base manager instead of the default manager." | The existence query inside `ForeignKey.validate()` must use `_base_manager`. | Encoded by SPEC O1 and K claim `FK_BASE_MANAGER_ACCEPTS`. |
| E2 | Problem statement | The form sets `self.fields['article'].queryset = Article._base_manager.all()` to allow archived articles. | Validation must accept a value visible through the base manager even if the default manager hides it. | Encoded by SPEC O2 and finding F1. |
| E3 | Problem statement | The failing user-facing error is "article instance with id 123 does not exist." | A base-visible row must not produce the invalid existence error solely because of default-manager filtering. | Encoded by PROOF_OBLIGATIONS PO1 and PO4. |
| E4 | Public hint | "At this level we're avoiding DB errors, not business logic errors, like 'was this archived', which properly belong to the form layer." | Model FK validation checks database existence, not default-manager business filtering. | Encoded by SPEC O3. |
| E5 | Public hint | "This is a change to model validation to allow the form validation to work." | The repair belongs in ORM model field validation, not form queryset construction. | Supports keeping formfield defaults unchanged. |
| E6 | Existing source | `ForeignKey.validate()` already applies `complex_filter(self.get_limit_choices_to())`. | Explicit `limit_choices_to` constraints remain part of validation. | Encoded by SPEC O4 and PO3. |
| E7 | Existing source | Forward and reverse related descriptors use related models' `_base_manager` for dereference querysets. | Using `_base_manager` for relation existence is compatible with internal relation resolution patterns. | Compatibility support; not sole intent source. |
| E8 | Existing source | `ForeignKey.validate()` already routes with `router.db_for_read(..., instance=model_instance)`. | The patch should preserve routing behavior unless public intent requires otherwise. | Encoded by SPEC O5 and PO2. |
