# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbols

| Symbol | Change | Public compatibility result |
| --- | --- | --- |
| `SQLCompiler.get_order_by()` | Narrows default metadata ordering selection to `query.group_by is None`. Signature and return shape are unchanged. | Compatible. Existing callers still receive the same list shape. Explicit and extra ordering are preserved. |
| `QuerySet.ordered` | Changes the default-ordering branch from a truthiness check to the documented `group_by is None` sentinel. Property signature and type are unchanged. | Compatible with public comment that default ordering does not affect grouped queries. It only changes metadata-only grouped states where the previous result disagreed with the compiler sentinel. |

## Callsite and override audit

No public function signatures, virtual dispatch arguments, return types, or
storage formats changed. The compiler call chain remains:

`pre_sql_setup()` -> `get_order_by()` -> `get_extra_select()` -> `get_group_by()`.

No subclass override needs a new parameter or return type. No test files were
modified.
