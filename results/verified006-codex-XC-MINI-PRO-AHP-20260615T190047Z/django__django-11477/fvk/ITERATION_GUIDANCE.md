# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged. The FVK audit did not surface a source-code defect requiring a V2 edit.

## Why No Source Edit Is Needed

- F1 and PO-1 show that keyword `None` from `resolve()` is removed before candidate matching, which addresses the reported `translate_url()` and `set_language` failure path.
- F2 and PO-2 show that positional `None` is also removed, covering the direct `reverse()` and `{% url %}` use case from the public hint.
- F3 and PO-4 show that empty strings remain present, so the fix does not hide missing template variables.
- F4 and PO-5 show that the existing mixed-args/kwargs error remains intact.
- PO-6 and `PUBLIC_COMPATIBILITY_AUDIT.md` show that no public signature or caller protocol changed.

## Residual Work For A Runtime-Enabled Environment

Do not run these in this workspace, but in a real environment the next checks should be:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/url-reverse-spec.k
kprove fvk/url-reverse-spec.k
```

Then run the relevant Django URL reversing and i18n tests. Until then, treat the proof as constructed, not machine-checked, and keep integration tests.

