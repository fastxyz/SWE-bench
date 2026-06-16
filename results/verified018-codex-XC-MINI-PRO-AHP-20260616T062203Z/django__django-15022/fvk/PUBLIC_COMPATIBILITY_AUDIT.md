# Public Compatibility Audit

Status: constructed from source inspection, not machine-checked.

## Changed public symbol

`django.contrib.admin.options.ModelAdmin.get_search_results(request, queryset, search_term)`

- Signature: unchanged.
- Return shape: unchanged `(queryset, may_have_duplicates)`.
- Override contract: unchanged. Subclasses overriding the method still receive
  the same arguments and return the same tuple shape.
- Callers: `ChangeList.get_queryset()` and autocomplete code still call the
  method with the same argument list.
- Queryset API usage: changed from one `filter(Q)` call per token to one
  `filter(*term_queries)` call after all token clauses are built.

## Compatibility verdict

No public API, method signature, virtual-dispatch call, return type, storage
format, or producer/consumer shape changed. Compatibility obligation O7 passes.
