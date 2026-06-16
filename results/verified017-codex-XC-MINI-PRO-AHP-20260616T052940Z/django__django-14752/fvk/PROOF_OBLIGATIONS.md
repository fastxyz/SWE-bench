# FVK Proof Obligations

Status: constructed, not machine-checked. No tests, Python code, or K tooling were executed.

## PO-1 - `get()` Delegates Per-Object Serialization

Intent trace: INT-1, INT-4, F-001.

Statement:

For every successful autocomplete response and every object `obj` in `context['object_list']`, the corresponding element of the JSON `results` list is the value returned by `self.serialize_result(obj, to_field_name)`.

Formal claim:

```k
claim buildResponse(OBJECTS, FIELD, MORE, HOOK)
  => response(mapResults(OBJECTS, FIELD, HOOK), MORE)
```

Why V1 discharges it:

`AutocompleteJsonView.get()` constructs `results` as a list comprehension whose element expression is `self.serialize_result(obj, to_field_name)`.

## PO-2 - Default Serializer Preserves Legacy Item Shape

Intent trace: INT-2, F-002.

Statement:

For the default `AutocompleteJsonView`, `serialize_result(obj, to_field_name)` returns exactly `{'id': str(getattr(obj, to_field_name)), 'text': str(obj)}`.

Formal claim:

```k
claim applyHook(defaultHook, obj(ID, TEXT), FIELD)
  => result(ID, TEXT)
```

Why V1 discharges it:

The new method body is exactly the original inline dictionary expression.

## PO-3 - Subclass Overrides Are Dynamically Dispatched

Intent trace: INT-1, INT-4, F-001, F-004.

Statement:

If a subclass overrides `serialize_result(self, obj, to_field_name)`, `get()` calls the subclass implementation for each object rather than hard-coding the default item dictionary.

Formal claim:

```k
claim buildResponse(OBJECTS, FIELD, MORE, customHook(NAME))
  => response(mapResults(OBJECTS, FIELD, customHook(NAME)), MORE)
```

Why V1 discharges it:

The call is `self.serialize_result(...)`, so normal Python method dispatch applies to subclasses.

## PO-4 - Pagination and Response Envelope Are Framed

Intent trace: INT-3, INT-5, F-003.

Statement:

Extracting per-result serialization must not change the response envelope. The response still has top-level `results` and `pagination`, and `pagination.more` is still `context['page_obj'].has_next()`.

Formal claim:

```k
claim buildResponse(OBJECTS, FIELD, MORE, HOOK)
  => response(mapResults(OBJECTS, FIELD, HOOK), MORE)
```

Why V1 discharges it:

The only changed expression is the element expression inside `results`; the `pagination` expression is unchanged.

## PO-5 - Public API Compatibility

Intent trace: INT-5, F-004.

Statement:

The new extension point must not break existing public callers or in-tree subclasses, and the override signature must match the issue's proposed customization.

Compatibility checks:

- `serialize_result` did not exist before V1, so no old override has to remain callable.
- The new call is positional: `self.serialize_result(obj, to_field_name)`.
- The issue's proposed override signature is `def serialize_result(self, obj, to_field_name)`.
- `AdminSite.autocomplete_view()` and `AutocompleteMixin.get_url()` remain unchanged.

Why V1 discharges it:

The new hook is additive and called with the exact two arguments from the public proposal.

## PO-6 - Verification Commands, Recorded Only

The following commands are the machine-check step a full FVK run would execute. They were not run because this task forbids execution:

```sh
cd fvk
kompile mini-python-autocomplete.k --backend haskell
kast --backend haskell autocomplete-spec.k
kprove autocomplete-spec.k
```

Expected result after a successful machine check:

- `kprove` returns `#Top` for the claims in `fvk/autocomplete-spec.k`.

Current status:

- Constructed, not machine-checked.
