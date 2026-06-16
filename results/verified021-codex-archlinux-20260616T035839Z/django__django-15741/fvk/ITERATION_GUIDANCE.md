# Iteration Guidance

Status: constructed, not machine-checked.

## Source Decision

Keep V1 unchanged. The FVK findings and proof obligations support the exact
source shape already present:

- F-001 / PO-001 through PO-004 require lazy string normalization in
  `get_format()` before every cache, module, settings, and fallback use.
- F-002 / PO-006 require the shared helper to be patched, not just the date
  template filter.
- F-003 / PO-005 reject broad coercion of arbitrary non-string inputs.

V1 satisfies all three by importing `Promise` and applying:

```python
if isinstance(format_type, Promise):
    format_type = str(format_type)
```

inside `get_format()` before `cache_key` and all later lookup/fallback paths.

## No Additional Code Changes

No source edit is recommended by this FVK pass. Moving the normalization later
would leave at least one lookup path exposed. Coercing all inputs with `str()`
would violate the frame condition. Patching only template filters would leave
direct `get_format()` callers exposed.

## Follow-up Verification

When an execution environment is available, run the emitted commands:

```sh
cd fvk
kompile mini-django-formats.k --backend haskell
kast --backend haskell get-format-spec.k
kprove get-format-spec.k
```

Do not remove tests based on this constructed proof until `kprove` returns
`#Top`.

## Suggested Tests To Keep Or Add

Keep or add coverage for:

- `get_format(gettext_lazy("Y-m-d")) == "Y-m-d"` on the arbitrary-format path.
- The `date` template filter with a lazy format argument.
- A lazy string naming a registered/custom format, to cover lookup rather than
  only arbitrary fallback.
