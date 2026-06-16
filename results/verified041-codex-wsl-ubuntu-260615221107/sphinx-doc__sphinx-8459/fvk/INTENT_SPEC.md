# Intent Spec

Status: constructed, not machine-checked.

## Required behavior from public intent

1. When `autodoc_typehints` is `description`, autodoc must render type hints in
   the generated description fields rather than in the visible signature.
2. `autodoc_type_aliases` maps postponed annotation names to fully qualified alias
   targets and is intended to keep those aliases from being expanded in generated
   documentation.
3. The alias behavior must be mode-independent for the reported case: an alias that
   appears as `types.JSONObject` in signature mode must also appear as
   `types.JSONObject` when type hints are moved into description fields.
4. The function parameter type field and the return type field are both in scope.
   In the issue example, `data: JSONObject` and `-> JSONObject` must both render as
   `types.JSONObject`.
5. Existing field-list merge behavior should be preserved except for the corrected
   string being inserted. Existing user-written `:type:` / `:rtype:` fields should
   still prevent duplicate generated fields.

## Domain and assumptions

* Domain: Python autodoc processing of callable objects whose annotations can be
  obtained by `sphinx.util.inspect.signature()`.
* Domain: alias mappings are the documented `autodoc_type_aliases` dictionary.
* Default-domain assumption: `inspect.signature(..., type_aliases=aliases)` is the
  established Sphinx resolver for alias-aware annotation strings because the
  existing signature path and public alias tests use that path.
* Partial-correctness scope: the FVK proof covers the annotation-recording and
  field-merge observable if the autodoc event pipeline reaches those functions.
