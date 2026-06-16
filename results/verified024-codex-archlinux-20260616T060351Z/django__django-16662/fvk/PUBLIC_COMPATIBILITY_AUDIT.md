# Public Compatibility Audit

Status: constructed, not machine-checked.

Changed production symbol: none. V1 edits only a local sort key expression inside
`MigrationWriter.as_string()`.

Public API signatures: unchanged.

Serializer return shape: unchanged. Serializers still return `(string, imports)`
where `imports` is a set of import strings.

Migration file structure: unchanged except for import line order.

Subclass/override dispatch: not applicable. No virtual call signature or method
contract changed.

Compatibility conclusion: pass. PO-7 is discharged.
