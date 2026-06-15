# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## F1: Whole-string lowercasing caused the reported lazy-reference failure

Classification: code bug, resolved by V1.

Input:

```text
remote_field.model == "DJ_RegLogin.Category"
```

Observed before V1:

```text
kwargs["to"] == "dj_reglogin.category"
```

Expected:

```text
kwargs["to"] == "DJ_RegLogin.category"
```

Evidence: problem statement reports the lazy reference to `dj_reglogin.category`, while the installed app label is `DJ_RegLogin`. The public hint states that app labels are case-sensitive in migrations. `make_model_tuple()` and `_meta.label_lower` both support preserving the app label and lowercasing only the model name.

Proof obligations: PO1, PO2, PO4.

Disposition: V1 satisfies this finding by splitting the string relation into app label and model name, then lowercasing only the model-name component.

## F2: No blocking gap found in the concrete-model branch

Classification: confirmed frame condition.

Input:

```text
remote_field.model is a model class with _meta.app_label == "DJ_RegLogin"
and _meta.model_name == "category"
```

Observed in source:

```text
kwargs["to"] = self.remote_field.model._meta.label_lower
```

Expected:

```text
"DJ_RegLogin.category"
```

Evidence: `Options.label_lower` formats `app_label` unchanged and `model_name` already lowercase.

Proof obligations: PO3.

Disposition: no source change required.

## F3: Swappable wrapping does not invalidate the app-label preservation obligation

Classification: confirmed frame condition.

Input:

```text
swappable_setting is not None after kwargs["to"] has been computed
```

Observed in source:

```text
kwargs["to"] = SettingsReference(kwargs["to"], swappable_setting)
```

Expected:

```text
The inner reference is the already computed app-preserving value.
```

Evidence: the swappable branch wraps `kwargs["to"]`; it does not call `.lower()` or recompute the reference.

Proof obligations: PO3, PO5.

Disposition: no source change required.

## F4: Adjacent migration reference utility lowercasing is not the operative cause here

Classification: non-blocking audit note.

Input:

```text
django/db/migrations/operations/utils.resolve_relation("DJ_RegLogin.Category", ...)
```

Observed in source:

```text
return tuple(model.lower().split('.', 1))
```

Expected for this issue's operative path:

```text
The value checked by StateApps must already be "DJ_RegLogin.category".
```

Evidence: the reported ValueError is raised by `StateApps.__init__()` through `_check_lazy_references()`. The path to that error is `ModelState.from_model()` -> `field.clone()` -> `ForeignObject.deconstruct()` -> model rendering -> pending lazy operations. The operations utility is used for migration operation reference bookkeeping and reduction, not for producing the pending lazy-reference key in the reported crash.

Proof obligations: PO4, PO6.

Disposition: not changed in this repair. A broader migration-optimizer audit could consider whether that utility should mirror `make_model_tuple()` for mixed-case app labels, but it is not needed to satisfy the current proof obligations.

## F5: Proof is constructed, not machine-checked

Classification: proof caveat.

Input:

```text
fvk/mini-python.k and fvk/related-deconstruct-spec.k
```

Observed:

```text
K commands are written in PROOF.md but were not executed.
```

Expected:

```text
No claim of machine-checked success until kprove returns #Top.
```

Proof obligations: all.

Disposition: keep test-removal recommendations conditional on future machine checking.

