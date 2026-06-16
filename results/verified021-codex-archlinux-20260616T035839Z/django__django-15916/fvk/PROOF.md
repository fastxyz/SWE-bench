# PROOF.md

Status: constructed, not machine-checked. No K tooling was executed.

## Claims Proved Constructively

The proof covers the callback-resolution abstraction in
`fvk/mini-python-form-callback.k` and `fvk/modelform-callback-spec.k`.

- `META-DIRECT`: direct `Meta.formfield_callback` is used when no top-level
  override exists.
- `TOP-LEVEL-OVERRIDE`: an explicit top-level callback wins over `Meta`.
- `TOP-LEVEL-NONE-DISABLES`: explicit top-level `None` disables a `Meta`
  callback.
- `FACTORY-OMITTED-PRESERVES-META`: omitted factory callback preserves inherited
  `Meta` callback.
- `FACTORY-EXPLICIT-OVERRIDES-META`: explicit factory callback wins.
- `FACTORY-FALSEY-NON-NONE-OVERRIDES`: a falsey non-`None` factory callback is
  still explicit.
- `INHERITED-META-PRESERVES`: child form without replacement `Meta` inherits
  the parent `Meta` callback.
- `REPLACED-META-DOES-NOT-LEAK-BASE`: child form with replacement `Meta` and no
  callback does not use the base callback.

## Symbolic Execution Proof

No loops or recursion occur in this reduced semantics, so there are no
circularities. Each claim is discharged by one or two rewrite steps.

### Direct Metaclass Resolution

`resolve(present(CB), META)` rewrites to `CB` by the first `resolve` rule.
Instantiating `CB = cbTop` proves `TOP-LEVEL-OVERRIDE`; instantiating
`CB = cbNone` proves `TOP-LEVEL-NONE-DISABLES`.

`resolve(absent, META)` rewrites to `META` by the second `resolve` rule.
Instantiating `META = cbMeta` proves `META-DIRECT`.

### Factory Omission

`factoryClassAttrs(cbNone, cbMeta)` rewrites to `resolve(absent, cbMeta)` by
the factory-omission rule. `resolve(absent, cbMeta)` rewrites to `cbMeta` by
the metaclass absent-override rule. By transitivity, omitted factory callback
preserves `cbMeta`.

### Factory Explicit Override

For any `CB` with side condition `CB =/=K cbNone`,
`factoryClassAttrs(CB, META)` rewrites to `resolve(present(CB), CB)`. The
explicit top-level rule then rewrites this to `CB`.

Instantiating `CB = cbFactory` proves `FACTORY-EXPLICIT-OVERRIDES-META`.
Instantiating `CB = cbFalsey` proves `FACTORY-FALSEY-NON-NONE-OVERRIDES`.

### Meta Inheritance Cases

`childWithInheritedMeta(cbBase)` rewrites to `resolve(absent, cbBase)`, then to
`cbBase`. This models normal Python resolution when a subclass does not define
its own `Meta`.

`childWithReplacedMeta(cbBase)` rewrites to `resolve(absent, cbNone)`, then to
`cbNone`. This models normal Python resolution when a subclass defines a
replacement `Meta` without a callback. The V1 fallback to `cbBase` would fail
this claim.

## Connection To Source

The V2 source implements the rules as follows:

- `formfield_callback_provided = "formfield_callback" in attrs` records whether
  a top-level override exists.
- `formfield_callback = attrs.pop("formfield_callback", None)` obtains that
  override value without confusing absence and explicit `None`.
- `opts = ModelFormOptions(meta)` reads the resolved inner `Meta` object.
- `if not formfield_callback_provided: formfield_callback =
  opts.formfield_callback` implements `resolve(absent, META)`.
- `opts.formfield_callback = formfield_callback` records the selected callback
  and the `fields_for_model(..., opts.formfield_callback, ...)` call passes it
  to field generation.
- `modelform_factory()` adds top-level and `Meta` callback attributes only when
  `formfield_callback is not None`.

## Machine-Check Commands

These commands are recorded for later machine checking. They were not run.

```sh
kompile fvk/mini-python-form-callback.k --backend haskell
kast --backend haskell fvk/modelform-callback-spec.k
kprove fvk/modelform-callback-spec.k
```

Expected machine-check result after a valid K setup: `kprove` returns `#Top` for
all claims.

## Residual Risk

This is a partial-correctness proof over a reduced semantics. It does not prove
termination, complete Python descriptor behavior, or all of Django's metaclass
machinery. The abstraction is adequate for the issue because the observable
bug is the identity of the callback passed to field generation.

## Test Recommendation

No tests were modified. If machine checking later returns `#Top`, focused unit
tests that assert the eight in-domain callback-resolution cases above are
subsumed by the proof. Integration tests, error-path tests for
`fields_for_model()` callability validation, and any tests outside the modeled
domain should be kept.
