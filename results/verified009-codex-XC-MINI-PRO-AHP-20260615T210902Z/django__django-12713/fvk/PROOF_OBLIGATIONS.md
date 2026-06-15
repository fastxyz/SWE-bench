# FVK Proof Obligations: django__django-12713

Status: constructed, not machine-checked.

The K-style claims live in `fvk/admin-widget-spec.k`; the minimal semantics live in `fvk/mini-admin-widget.k`.

## OBL-001: Explicit widget precedence

For every auto-created many-to-many field and every admin widget configuration, if `kwargs` contains `widget = W`, then `db_field.formfield(**kwargs)` receives widget `W`.

Trace:

- Evidence: E-001, E-002, E-003.
- Finding: F-001.
- Code path: `if 'widget' not in kwargs:` is false, so no autocomplete/raw-id/filter assignment can overwrite `kwargs['widget']`.
- Formal claim: `m2mFormfield(true, someWidget(W), A, Q) => formField(W, QS)`.

## OBL-002: Default admin widget frame

For every auto-created many-to-many field with no explicit `widget`, existing admin widget selection remains unchanged.

Trace:

- Evidence: E-007.
- Finding: F-002.
- Code path: the new guard is true when `widget` is absent, so the prior branch order still applies: autocomplete, then raw-id, then filtered select, then model field default.
- Formal claims: `autocompleteOption`, `rawIdOption`, `filteredOption`, and `noAdminWidget` claims in `admin-widget-spec.k`.

## OBL-003: Queryset frame

The widget fix must not change queryset precedence.

Trace:

- Evidence: E-004 and existing code around `if 'queryset' not in kwargs:`.
- Finding: F-003.
- Code path: queryset logic remains after widget selection and still only infers a queryset when no explicit queryset exists.
- Formal model: `finalize(W, noQueryset) => formField(W, inferredQueryset)` and explicit queryset remains explicit.

## OBL-004: Non-auto-created through model frame

Many-to-many fields with a non-auto-created intermediary model must still produce no admin form field.

Trace:

- Evidence: E-006.
- Finding: F-003.
- Code path: the early `return None` remains before widget selection.
- Formal claim: `m2mFormfield(false, W, A, Q) => noFormField`.

## OBL-005: `formfield_for_dbfield()` override precedence frame

When `formfield_for_dbfield()` merges `formfield_overrides` and incoming `kwargs`, incoming `kwargs` remain more specific.

Trace:

- Evidence: E-005.
- Finding: F-003.
- Code path: `kwargs = {**self.formfield_overrides[db_field.__class__], **kwargs}` is unchanged, so an explicit widget remains present before the M2M helper's new guard.
- Formal relation: callers reaching OBL-001 with `someWidget(W)` preserve `W`.

## OBL-006: Public compatibility

The fix must not alter method signature, return category, or virtual dispatch compatibility.

Trace:

- Evidence: E-004 and public override/callsite audit in `SPEC.md`.
- Finding: F-004.
- Code path: no signature change and no new keyword argument; existing overrides accepting `**kwargs` remain compatible.
- Formal relation: compatibility is a side condition for accepting the proof, not a separate K reachability claim.

## Machine-check Commands Not Run

Per task constraints, these commands were recorded but not executed:

```sh
cd fvk
kompile mini-admin-widget.k --backend haskell
kast --backend haskell admin-widget-spec.k
kprove admin-widget-spec.k
```
