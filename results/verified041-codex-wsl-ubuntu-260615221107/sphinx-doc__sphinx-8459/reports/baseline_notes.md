# Baseline Notes

## Root cause

When `autodoc_typehints` is set to `description`, Sphinx records annotations during the
`autodoc-process-signature` event and later merges those recorded values into the
generated field list. That recording path called `sphinx.util.inspect.signature(obj)`
without passing `app.config.autodoc_type_aliases`.

The normal signature rendering path already passes `autodoc_type_aliases`, so aliases
such as `JSONObject` can remain rendered as the configured alias target. The
description-mode path skipped that configuration and therefore resolved the annotation
to the underlying typing object, producing values like `Dict[str, Any]`.

## Changed files

* `repo/sphinx/ext/autodoc/typehints.py`
  * Updated `record_typehints()` to pass `type_aliases=app.config.autodoc_type_aliases`
    when obtaining the signature used for recorded type hints.
  * This keeps description-mode type rendering aligned with the existing signature-mode
    behavior without changing the later field-list merge logic.

## Assumptions and alternatives considered

* I assumed `autodoc_type_aliases` should apply uniformly to all autodoc type-hint
  rendering modes, matching the issue's expected output and the existing signature
  rendering behavior.
* I considered changing `typing.stringify()` to be alias-aware, but rejected that because
  alias resolution already belongs to `sphinx.util.inspect.signature()` in this codebase
  and broadening `stringify()` would affect unrelated callers.
* I considered modifying the field-list merge step, but rejected that because by then the
  annotations have already been converted to strings; the correct fix is to record the
  alias-aware annotations before stringification.
* I did not modify tests, per the task constraints, and did not run the test suite or any
  project code.
