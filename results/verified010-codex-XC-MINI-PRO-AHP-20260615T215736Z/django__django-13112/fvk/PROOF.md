# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Target

The proof target is the `kwargs["to"]` value computed by `ForeignObject.deconstruct()` for migration-state cloning of relation fields.

## Claims

The K claims are in `fvk/related-deconstruct-spec.k`, with semantics in `fvk/mini-python.k`.

- `LAZY-REF-PRESERVES-APP-LABEL`: `serialize(lazyRef(APP, MODEL))` reaches `toRef(APP, lowerModelName(MODEL))`.
- `REPORTED-CASE`: `serialize(lazyRef("DJ_RegLogin", "Category"))` reaches `toRef("DJ_RegLogin", "category")`.
- `LEGACY-REPORTED-CASE`: the pre-V1 whole-string-lowercase abstraction reaches `toRef("dj_reglogin", "category")`, showing the discriminator for the reported failure.
- `CONCRETE-REF-LABEL-LOWER`: `serialize(concreteRef(APP, MODEL_LOWER))` reaches `toRef(APP, MODEL_LOWER)`.

## Proof sketch

For the lazy-reference branch, symbolic execution starts with a parsed normalized relation `lazyRef(APP, MODEL)`. The V1 source performs one split step that binds `app_label = APP` and `model_name = MODEL`, then constructs `"%s.%s" % (app_label, model_name.lower())`. The corresponding K rule rewrites directly to `toRef(APP, lowerModelName(MODEL))`.

The app-label preservation postcondition follows by reflexive equality on the first component: the rule's output first component is the same symbolic `APP` matched in the input. The model-name normalization postcondition follows from applying `lowerModelName()` only to `MODEL`.

For the reported concrete value, the verification module includes simplification rules for the two public strings:

```text
lowerModelName("Category") = "category"
lowerModelName("DJ_RegLogin") = "dj_reglogin"
```

The V1 claim therefore reaches `toRef("DJ_RegLogin", "category")`. The legacy abstraction rewrites the app component through `lowerModelName(APP)` as well, reaching `toRef("dj_reglogin", "category")`. This distinguishes the passing and failing cases on the app-label axis.

For the concrete-model branch, source inspection shows `kwargs["to"] = self.remote_field.model._meta.label_lower`. `Options.label_lower` is `'%s.%s' % (self.app_label, self.model_name)`, so app label case is preserved and the model component is already the lowercase model key.

For the swappable branch, source inspection shows `SettingsReference(kwargs["to"], swappable_setting)` wraps the value already computed by the string or concrete branch. No additional lowercasing occurs.

There are no loops or recursive calls in the audited code path, so no circularity claim is needed. This is a partial-correctness proof of the returned/deconstructed value; termination is not separately proved.

## Machine-check commands not run

These are the commands that would be used later in an environment with K installed:

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell related-deconstruct-spec.k
kprove related-deconstruct-spec.k
```

Expected machine-check result after the toolchain is available: `#Top` for all claims.

## Test guidance

Do not remove tests based on this constructed proof alone. If the K proof is later machine-checked, unit tests that only assert the in-domain transformation from `DJ_RegLogin.Category` to `DJ_RegLogin.category` are subsumed by `REPORTED-CASE`, but integration tests for migration rendering and app-registry resolution should be kept.
