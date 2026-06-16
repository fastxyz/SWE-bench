# Proof Obligations

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

| ID | Obligation | Evidence / claim | Status |
| --- | --- | --- | --- |
| PO1 | The intended domain is SQLite `AlterField` decisions for choices-only changes on Django fields where `choices` is metadata. | Intent ledger I1-I2; finding F1. | Discharged by spec scope. |
| PO2 | The base ignored-attribute set remains exactly the previous set and does not include `choices`. | Source diff in `repo/django/db/backends/base/schema.py`; finding F3. | Discharged by static inspection. |
| PO3 | SQLite's ignored-attribute set equals the base set plus exactly `choices`. | Source diff in `repo/django/db/backends/sqlite3/schema.py`; claim `SQLITE-CHOICES-NOOP`. | Discharged by static inspection and constructed claim. |
| PO4 | A choices-only difference remains an alteration candidate under the base editor. | Claim `BASE-CHOICES-STILL-ALTERS`; finding F3. | Constructed, not machine-checked. |
| PO5 | A choices-only difference is not an alteration under SQLite. | Claim `SQLITE-CHOICES-NOOP`; finding F1. | Constructed, not machine-checked. |
| PO6 | SQLite still classifies non-choices database-relevant changes as alterations. | Claim `SQLITE-SCHEMA-ATTR-STILL-ALTERS`. | Constructed, not machine-checked. |
| PO7 | SQLite still classifies quoted-column changes as alterations. | Claim `SQLITE-COLUMN-STILL-ALTERS`. | Constructed, not machine-checked. |
| PO8 | The V2 refactor does not introduce a public-looking base hook or change method signatures. | Finding F2; compatibility audit in `PUBLIC_COMPATIBILITY_AUDIT.md`. | Discharged by static inspection. |
| PO9 | The repair does not modify tests and does not rely on unrun tests/tooling. | Task constraints; finding F5. | Discharged by status/diff inspection. |

## Generated Verification Commands

These commands are artifacts only. They were not executed.

```sh
kompile fvk/mini-schema-editor.k --backend haskell
kast --backend haskell fvk/schema-editor-spec.k
kprove fvk/schema-editor-spec.k
```
