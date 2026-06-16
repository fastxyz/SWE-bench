# FVK Spec

Status: constructed, not machine-checked. No tests, Python code, or K tooling were executed.

## Scope

Audited production source: `repo/django/contrib/admin/views/autocomplete.py`.

Target units:

- `AutocompleteJsonView.get()`
- `AutocompleteJsonView.serialize_result()`

The issue concerns successful autocomplete JSON responses. Existing validation and error behavior in `process_request()`, permission checks, queryset construction, and pagination internals are treated as frame conditions except where they contribute to the final response shape.

## Intent-Only Obligations

INT-1: Add a result-customization extension point.

- Source: `benchmark/PROBLEM.md`
- Evidence: "adding a result customization extension point to get() by moving the lines that construct the results inside JsonResponse constructor to a separate method"
- Obligation: `get()` must delegate each per-object result dictionary to an overridable method.
- Status: encoded by PO-1 and PO-3.

INT-2: Preserve the default per-object response.

- Source: `benchmark/PROBLEM.md`
- Evidence: "where serialize_result() contains the original object to dictionary conversion code"
- Obligation: the default hook returns `{'id': str(getattr(obj, to_field_name)), 'text': str(obj)}`.
- Status: encoded by PO-2.

INT-3: Preserve the surrounding JSON response.

- Source: `benchmark/PROBLEM.md`
- Evidence: the proposed after snippet changes only the result item expression; `pagination` remains `{'more': context['page_obj'].has_next()}`
- Obligation: result serialization changes must not alter request processing, permission checks, queryset context, pagination shape, or the pagination boolean source.
- Status: encoded by PO-4.

INT-4: Allow subclass customization without overriding `get()`.

- Source: `benchmark/PROBLEM.md`
- Evidence: "The example CustomAutocompleteJsonView from above would now become succinct and maintainable: class CustomAutocompleteJsonView(AutocompleteJsonView): def serialize_result(...)"
- Obligation: subclasses can override `serialize_result(self, obj, to_field_name)` and have `get()` call the override dynamically for every object.
- Status: encoded by PO-3 and PO-5.

INT-5: Keep the change low risk.

- Source: `benchmark/PROBLEM.md` and public hint
- Evidence: "simple, side-effect- and risk-free"; hint says "Makes sense to me."
- Obligation: no unrelated source behavior should change.
- Status: encoded by PO-4 and PO-5.

## Domain and Frame Conditions

The in-domain successful-response path assumes:

- `process_request(request)` returns `(term, model_admin, source_field, to_field_name)`.
- `has_perm(request)` returns true.
- `get_queryset()` and `get_context_data()` return normally.
- `context['object_list']` is a finite ordered collection of objects.
- Each default-serialized object has an attribute named by `to_field_name`, and `str(getattr(obj, to_field_name))` and `str(obj)` return strings.
- `context['page_obj'].has_next()` returns a boolean.
- A custom `serialize_result()` implementation returns a JSON-serializable value suitable for Select2 result items. The framework hook guarantees dispatch and placement, not the custom value's internal correctness.

Out of scope for this issue:

- malformed request parameters and permission-denied branches;
- queryset search semantics;
- paginator internals;
- JavaScript rendering behavior beyond the established Select2-compatible `results` and `pagination.more` response shape.

## Formal Model Summary

The K model in `fvk/mini-python-autocomplete.k` abstracts a model object to `obj(ID, TEXT)`, where `ID` is the string form of `getattr(obj, to_field_name)` and `TEXT` is `str(obj)`. It abstracts the serializer hook to either `defaultHook` or a symbolic `customHook(NAME)`.

The K claims in `fvk/autocomplete-spec.k` state:

- default serializer claim: `applyHook(defaultHook, obj(ID, TEXT), FIELD) => result(ID, TEXT)`;
- response construction claim: `buildResponse(OBJECTS, FIELD, MORE, HOOK) => response(mapResults(OBJECTS, FIELD, HOOK), MORE)`;
- default composition claim: `buildResponse(OBJECTS, FIELD, MORE, defaultHook) => response(defaultResults(OBJECTS), MORE)`.

## Public Compatibility Audit

Changed public symbol: `AutocompleteJsonView.serialize_result(self, obj, to_field_name)`.

Compatibility findings:

- The new method did not previously exist, so no pre-existing in-tree override can have an incompatible signature.
- `get()` calls `self.serialize_result(obj, to_field_name)` with positional arguments only, matching the issue's proposed override signature and avoiding keyword-only compatibility hazards.
- `AdminSite.autocomplete_view()` still constructs `AutocompleteJsonView.as_view(admin_site=self)(request)` and does not change request routing.
- `AutocompleteMixin` still points Select2 widgets at the same autocomplete URL and does not consume any new required response fields.
- Extra result keys are additive per the issue's stated use case; default result keys remain `id` and `text`.

## Adequacy Audit

The formal claims match the intent obligations:

- PO-1 and PO-3 capture INT-1 and INT-4 because the observable result list is defined by dynamic `applyHook`/`serialize_result` dispatch for each object.
- PO-2 captures INT-2 because the default hook returns exactly the old `id` and `text` fields.
- PO-4 captures INT-3 because the `MORE` flag is framed through response construction unchanged.
- PO-5 captures INT-5 because the dispatch call is positional and no existing routing or widget producer/consumer protocol changes.

No formal claim depends solely on V1's behavior. Each nontrivial obligation traces to the problem statement or the public source shape needed to model it.
