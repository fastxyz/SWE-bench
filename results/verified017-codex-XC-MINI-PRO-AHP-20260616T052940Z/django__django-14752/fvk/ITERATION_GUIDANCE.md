# FVK Iteration Guidance

Status: constructed, not machine-checked. No tests, Python code, or K tooling were executed.

## Decision

Keep V1 source unchanged.

Rationale:

- F-001 and PO-1/PO-3 show that V1 resolves the reported extension-point defect.
- F-002 and PO-2 show that the default result item shape is preserved.
- F-003 and PO-4 show that pagination and the response envelope are preserved.
- F-004 and PO-5 show that the new hook is additive and compatible with the issue's proposed subclass API.
- F-005 records that no proof obligation calls for a V2 source edit.

## Recommended Next Human Checks

When an execution environment exists, run the project tests relevant to admin autocomplete. Do not remove tests based on this constructed proof alone.

If K tooling is available, machine-check the model with:

```sh
cd fvk
kompile mini-python-autocomplete.k --backend haskell
kast --backend haskell autocomplete-spec.k
kprove autocomplete-spec.k
```

Expected machine-check target: `kprove` returns `#Top`.

## Suggested Maintainer Tests

The hidden benchmark tests are fixed and were not inspected. Public maintainers could cover this behavior with tests that verify:

- `AutocompleteJsonView().serialize_result(obj, to_field_name)` returns the legacy `id` and `text` values.
- A custom view overriding `serialize_result()` contributes an extra field in each `results` item.
- The custom hook does not require overriding `get()`.
- The `pagination.more` value is unaffected by the serializer extraction.

## No Further Code Action

No alternative signature, hook placement, or response format is better supported by the public issue than the V1 implementation. A broader hook receiving `request`, `context`, or the whole result list remains rejected because it is not required by the intent and would enlarge the API surface without evidence.
