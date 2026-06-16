# PUBLIC_EVIDENCE_LEDGER

Status: constructed, not machine-checked.

This ledger mirrors the evidence table in `SPEC.md`.

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| I1 | problem | "restore the old auto-generated name" | Backwards must rename to the generated old name. |
| I2 | problem | "re-applying RenameIndex() crashes" | Round trip must be repeatable. |
| I3 | hint | "find the old name with SchemaEditor._create_index_name()" | Use `_create_index_name()` for the reverse target. |
| I4 | docs/source | `old_fields` corresponds to `index_together`; state removes `AlterIndexTogether.option_name` | Use the `"_idx"` generated index name. |
| I5 | source | Forwards checks `allow_migrate_model()` | Backwards should preserve skip behavior. |
| I6 | source | `schema_editor.rename_index()` handles backend capabilities | Use schema-editor delegation. |
| I7 | public test | "Reverse is a no-op." | SUSPECT legacy behavior, not an obligation. |
| I8 | problem wording | `unique_together` | Ambiguous; do not silently alter constraint semantics. |
