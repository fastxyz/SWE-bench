# FVK Proof: django__django-12713

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`, or `kprove` were run.

## What Is Proved

For `BaseModelAdmin.formfield_for_manytomany()`:

- If the many-to-many through model is not auto-created, the method returns no form field before any widget selection.
- If the field is auto-created and `kwargs` contains `widget`, that widget is preserved regardless of autocomplete/raw-id/filter configuration.
- If the field is auto-created and `kwargs` does not contain `widget`, existing admin default widget selection is preserved.
- Queryset handling and public override compatibility are unchanged.

## Constructed Proof Sketch

### OBL-001: Explicit widget precedence

Start state: auto-created through model, `kwargs` contains `widget = W`, arbitrary admin widget configuration.

Symbolic execution of V1:

1. The non-auto-created through guard is false, so execution continues.
2. The condition `if 'widget' not in kwargs:` is false.
3. The autocomplete/raw-id/filter assignment block is skipped.
4. Queryset handling may add or preserve `queryset`, but does not assign `widget`.
5. `db_field.formfield(**kwargs)` receives `kwargs['widget'] == W`.
6. The help-text post-processing can alter `help_text`; it does not replace `form_field.widget`.

Conclusion: the output form field's widget remains the caller-provided widget. This discharges F-001.

### OBL-002: Default admin widget frame

Start state: auto-created through model, no `widget` key.

Symbolic execution:

1. The non-auto-created through guard is false.
2. The condition `if 'widget' not in kwargs:` is true.
3. The body executes the same branch order as before V1: autocomplete first, then raw-id, then filtered select, otherwise no admin widget injection.
4. The selected widget is passed to `db_field.formfield(**kwargs)`.

Conclusion: V1 changes only the explicit-widget case and preserves default admin widget behavior.

### OBL-003 through OBL-005: Frame obligations

The queryset block, through-model early return, and `formfield_for_dbfield()` merge expression are textually unchanged by V1. Because the new guard only controls writes to `kwargs['widget']`, these paths keep their prior behavior.

### OBL-006: Compatibility

The public method signature remains `formfield_for_manytomany(self, db_field, request, **kwargs)`. No caller is required to pass a new argument, and no override must accept a new keyword. The production `GroupAdmin` override and documentation examples remain compatible because they already forward `**kwargs` to `super()`.

## Adequacy Check

The formal English claims in `SPEC.md` match the intent spec:

- The central claim is exactly the prompt's requested behavior: overriding `widget` must work.
- The frame claims are limited to behavior touched by the edit and supported by code/docs evidence.
- No claim preserves the reported pre-fix overwrite behavior.

## Residual Risk

- The proof is constructed, not machine-checked.
- The K semantics is a property-complete abstraction of widget precedence, not a full Python or Django semantics.
- Termination is not separately proved. The audited code path is straight-line conditional logic with no loop, so no loop circularity was needed.
- Integration behavior should remain covered by Django's test suite; no tests were removed.

## Test Recommendation

Do not remove tests. After machine-checking, unit tests that assert explicit widget precedence for `formfield_for_manytomany()` across autocomplete/raw-id/filter/default configurations would be subsumed by OBL-001, but integration tests for rendering, related-object wrappers, querysets, and permissions should be kept.

## Machine-check Commands Not Run

```sh
cd fvk
kompile mini-admin-widget.k --backend haskell
kast --backend haskell admin-widget-spec.k
kprove admin-widget-spec.k
```

Expected machine-check result if the abstraction and K syntax are accepted: `kprove` discharges the claims to `#Top`.
