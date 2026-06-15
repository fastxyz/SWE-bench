# Public Compatibility Audit

Status: constructed, not machine-checked.

Changed source symbol:

```text
ModelAdmin._get_edited_object_pks(self, request, prefix)
```

Compatibility result:

- Signature unchanged.
- Return type unchanged: a list of POST values.
- Internal caller unchanged:
  `_get_list_editable_queryset(request, FormSet.get_default_prefix())`.
- No new virtual dispatch arguments were introduced.
- No public override or callsite update is required.

Result: PASS.

