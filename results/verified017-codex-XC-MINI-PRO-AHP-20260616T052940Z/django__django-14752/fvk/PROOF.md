# FVK Proof

Status: constructed, not machine-checked. No tests, Python code, or K tooling were executed.

## Summary

The V1 code satisfies the issue's intent. `AutocompleteJsonView.get()` now constructs each item in `results` by dynamically calling `self.serialize_result(obj, to_field_name)`. The default `serialize_result()` returns the same `id` and `text` dictionary expression that was previously inline. The surrounding response envelope and pagination expression are unchanged.

## Proof Sketch

### PO-1 and PO-3

`get()` computes `context = self.get_context_data()` and returns a `JsonResponse` whose `results` value is a list comprehension over `context['object_list']`.

In V1, the list-comprehension element is:

```python
self.serialize_result(obj, to_field_name)
```

For any finite ordered object list `[o1, ..., on]`, Python evaluates the comprehension in that order and calls the method on `self` for each object. Because the method is looked up on `self`, subclass overrides participate in normal dynamic dispatch. Therefore the produced list is:

```text
[self.serialize_result(o1, to_field_name), ..., self.serialize_result(on, to_field_name)]
```

This is exactly PO-1. If `self` is an instance of a subclass that overrides `serialize_result`, the same call target resolves to that override, which discharges PO-3.

### PO-2

The default method body is:

```python
return {'id': str(getattr(obj, to_field_name)), 'text': str(obj)}
```

This is byte-for-byte the same result-item expression as the pre-extraction inline comprehension, except moved into a method. Therefore, for the default view, every object still produces the legacy `id` and `text` item. This discharges PO-2.

### PO-4

The `JsonResponse` envelope remains:

```python
{
    'results': [...],
    'pagination': {'more': context['page_obj'].has_next()},
}
```

V1 changes only the expression used for each element of `results`. It does not alter the top-level keys, the `pagination` key, or the source expression for `pagination.more`. This discharges PO-4.

### PO-5

The public compatibility audit found no source override of `serialize_result` in non-test `repo/django`, and the method did not exist before V1. The new virtual call is positional and matches the issue's proposed override signature. Existing admin routing and widget URL generation are unchanged. This discharges PO-5.

## K Claim Correspondence

The model claim:

```k
claim buildResponse(OBJECTS, FIELD, MORE, HOOK)
  => response(mapResults(OBJECTS, FIELD, HOOK), MORE)
```

corresponds to the list-comprehension mapping plus pagination framing.

The model claim:

```k
claim applyHook(defaultHook, obj(ID, TEXT), FIELD)
  => result(ID, TEXT)
```

corresponds to the default `serialize_result()` body, with `ID` abstracting `str(getattr(obj, to_field_name))` and `TEXT` abstracting `str(obj)`.

The model claim:

```k
claim buildResponse(OBJECTS, FIELD, MORE, defaultHook)
  => response(defaultResults(OBJECTS), MORE)
```

corresponds to composing `get()` with the default serializer and proves default output preservation for the audited response slice.

## Residual Risk

This is a partial-correctness proof over the successful-response path. It assumes `process_request()`, permission checks, queryset construction, context generation, `getattr()`, and `str()` return normally on the in-domain path. Those behaviors are outside the issue's requested refactor and are framed rather than re-proved.

The proof is constructed, not machine-checked. The K commands recorded in `PROOF_OBLIGATIONS.md` were not executed.

## Machine-Check Commands

Recorded only; not executed in this session:

```sh
cd fvk
kompile mini-python-autocomplete.k --backend haskell
kast --backend haskell autocomplete-spec.k
kprove autocomplete-spec.k
```

Expected machine-check target: `kprove` returns `#Top`.

## Test Recommendation

Do not delete tests. The task forbids running tests or K tooling, and this proof is not machine-checked. Useful public tests, if added by maintainers, would assert:

- default autocomplete JSON is unchanged for a representative object;
- a subclass overriding `serialize_result()` can add an extra key without overriding `get()`;
- `pagination.more` remains tied to `context['page_obj'].has_next()`.
