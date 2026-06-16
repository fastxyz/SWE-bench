# Iteration Guidance

Status: V1 stands unchanged after FVK audit.

## Source Decision

No additional production source edit is justified by the proof obligations.

- `F-01` is resolved by V1 through `PO-1`, `PO-2`, `PO-4`, `PO-5`, and `PO-6`.
- `F-02` is satisfied by V1 through `PO-3`, `PO-4`, `PO-6`, and `PO-7`.
- `F-03` is under-specified and does not justify changing V1's compatibility-preserving treatment of an explicitly empty string.
- `F-04` is a documentation/test coverage gap, not a runtime code defect in the audited source.
- `F-05` is a proof-process limitation caused by the no-execution constraint.

## Recommended Future Tests

Do not modify tests in this task. In a normal Django development pass, add tests equivalent to:

```python
json_script({"hello": "world"})
```

Expected output:

```html
<script type="application/json">{"hello": "world"}</script>
```

Also add a template-filter case equivalent to:

```django
{{ value|json_script }}
```

Expected output: the same no-ID script wrapper.

Keep the existing ID-present tests because they check compatibility for `F-02`.

## Recommended Future Documentation

In a normal documentation pass, update `repo/docs/ref/templates/builtins.txt` to say the ID argument is optional and include a no-ID example. This was not changed here because the requested benchmark repair target is runtime source plus FVK artifacts.

## Machine-Check Follow-up

When an execution environment is available, run:

```sh
kompile fvk/mini-python-json-script.k --backend haskell
kast --backend haskell fvk/json-script-spec.k
kprove fvk/json-script-spec.k
```

Only treat test-redundancy recommendations as actionable if `kprove` returns `#Top`.
