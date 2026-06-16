# ITERATION_GUIDANCE.md

Status: next-iteration guidance from the constructed FVK audit.

## Code Status

V2 should stand over V1. The FVK audit found one V1 problem:

- V1 used a separate base-form fallback for `formfield_callback`, which could
  make a child form with a replacement `Meta` inherit only that option from the
  base `Meta`. This conflicted with the documented normal Python `Meta`
  resolution rules. V2 removes that fallback.

No further source edits are justified by the current public evidence.

## Suggested Public Tests When Execution Is Available

Do not modify tests in this benchmark task. For a normal Django patch, add or
keep focused tests for:

1. `ModelForm.Meta.formfield_callback` is used on a directly declared
   `ModelForm`.
2. `modelform_factory(model, form=BaseForm)` with omitted callback uses
   `BaseForm.Meta.formfield_callback`.
3. An explicit `modelform_factory(..., formfield_callback=callback)` overrides
   a base `Meta` callback.
4. A subclass without its own `Meta` inherits the parent `Meta` callback.
5. A subclass with replacement `Meta` and no callback does not inherit only the
   base callback.
6. A falsey but non-`None` callable passed as `formfield_callback` is preserved.
7. A non-callable explicit callback still raises the existing `TypeError`.

## Machine Verification

When a K environment is available, run:

```sh
kompile fvk/mini-python-form-callback.k --backend haskell
kast --backend haskell fvk/modelform-callback-spec.k
kprove fvk/modelform-callback-spec.k
```

Keep all tests until `kprove` returns `#Top`; the proof here is constructed,
not machine-checked.
