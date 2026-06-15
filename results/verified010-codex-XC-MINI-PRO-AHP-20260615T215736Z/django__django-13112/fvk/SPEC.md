# FVK Spec for django__django-13112

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

The audited unit is the `kwargs['to']` construction in `ForeignObject.deconstruct()` in `repo/django/db/models/fields/related.py`. This is the serialization path used by `Field.clone()`, `ModelState.from_model()`, and `StateApps` rendering for relation fields.

The observable under audit is the model reference passed through migration state for a lazy related model. The specific public failure is a `ForeignKey` in app `DJ_RegLogin` becoming a lazy reference to `dj_reglogin.category`, which cannot resolve because app labels are case-sensitive.

## Public intent ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "makemigrations crashes for ForeignKey with mixed-case app name" | Relation serialization must not create a lowercased app label for mixed-case apps. | Encoded in PO1 and K claim `LAZY-REF-PRESERVES-APP-LABEL`. |
| E2 | prompt example | `INSTALLED_APPS = ['DJ_RegLogin', ...]` and `category = models.ForeignKey(Category, ...)` | For the reported app/model pair, the migration reference must resolve under app label `DJ_RegLogin`. | Encoded in concrete discriminator claim. |
| E3 | prompt hint | "app labels were always case sensitive in migrations" | The app-label component is case-sensitive and must be preserved exactly. | Encoded in PO1. |
| E4 | source doc | `make_model_tuple()` accepts strings of form `app_label.ModelName` and returns `("app_label", "modelname")`. | The normalized relation-string domain has exactly one dot; only the model component is lowercased. | Encoded in PO1 and PO2. |
| E5 | source property | `Options.label_lower` returns `'%s.%s' % (self.app_label, self.model_name)`. | Concrete model references already preserve app label and lowercase only model name. | Encoded in PO3. |
| E6 | source doc | `Apps.get_model()` says `model_name is case-insensitive`; `get_app_config()` indexes exact app labels. | Model names may be case-insensitive, but app labels are not. | Encoded in PO1 and PO2. |
| E7 | source path | `StateApps.__init__()` raises lazy-reference errors from `_check_lazy_references()`. | The deconstructed string must be correct before state rendering, or pending operations target the wrong app. | Encoded in PO4. |

## Intent-only contract

For a normalized lazy string relation `A.M`, where `A` is the installed app label and `M` is the model class/object name:

1. `ForeignObject.deconstruct()` must serialize `kwargs['to']` as `A + "." + lower(M)`, preserving every character of `A`.
2. It must continue to lowercase the model-name component, matching migration model-key conventions.
3. For concrete model references, the existing `_meta.label_lower` branch must remain equivalent to `A + "." + lower(M)`.
4. Swappable model wrapping may wrap the computed `to` value in `SettingsReference`, but must not recompute or lowercase the app-label component.
5. No public method signature, return tuple shape, or test file may change.

Invalid or unnormalized relation strings are outside this issue's in-scope domain. This follows `make_model_tuple()` and lazy operation keys, which require `app_label.ModelName` strings. Bare and recursive model strings are resolved relative to a model before the migration-state failure path under audit.

## Candidate behavior

V1 changed the string branch from:

```python
kwargs['to'] = self.remote_field.model.lower()
```

to:

```python
app_label, model_name = self.remote_field.model.split('.')
kwargs['to'] = '%s.%s' % (app_label, model_name.lower())
```

For `DJ_RegLogin.Category`, the candidate produces `DJ_RegLogin.category`.

## Adequacy summary

The formal claims in `fvk/related-deconstruct-spec.k` model the relation reference as a parsed pair, `lazyRef(APP, MODEL)`, rather than as an opaque string. This preserves the proof-relevant axis: the app-label component is distinguishable from the model-name component. A passing case and failing legacy case map to different values:

- Passing V1 abstraction: `toRef("DJ_RegLogin", "category")`.
- Failing legacy abstraction: `toRef("dj_reglogin", "category")`.

The spec is not derived from V1 alone. It is anchored in the public issue, the public hint about case-sensitive migration app labels, `make_model_tuple()`, `Options.label_lower`, and `Apps.get_model()`.
