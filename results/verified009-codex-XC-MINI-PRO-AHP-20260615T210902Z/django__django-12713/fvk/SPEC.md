# FVK Spec: django__django-12713

Status: constructed, not machine-checked.

## Scope

Target unit: `BaseModelAdmin.formfield_for_manytomany()` in `repo/django/contrib/admin/options.py`, plus the `formfield_for_dbfield()` path that passes `kwargs` into it.

Observable property: which widget is passed to `db_field.formfield(**kwargs)` for an auto-created many-to-many field.

Out of scope for this issue: rendering behavior of the selected widget, database query execution, and non-admin form construction. Those are frame conditions only where the edited code could affect them.

## Intent Spec

- INT-001: A caller-provided `widget` argument to `formfield_for_manytomany()` must be honored.
- INT-002: `formfield_for_manytomany()` should match `formfield_for_foreignkey()` on widget precedence: admin defaults apply only when `widget` is absent.
- INT-003: Existing admin widget defaults for many-to-many fields remain active when no explicit widget is provided.
- INT-004: Existing queryset precedence remains unchanged: explicit `queryset` wins; otherwise the admin may infer one from related model ordering.
- INT-005: Non-auto-created through models remain hidden in admin by returning no form field.
- INT-006: The public hook signature and `**kwargs` forwarding contract remain compatible with existing overrides.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | prompt | "Allow overridding widget in formfield_for_manytomany()." | Explicit `widget` must win over automatic many-to-many widget selection. | Encoded by OBL-001 / claim explicit widget. |
| E-002 | prompt | "It does not work when I set widget param to function formfield_for_manytomany()." | Pre-fix overwrite is the reported bug, not behavior to preserve. | Encoded as Finding F-001. |
| E-003 | prompt | "This is different from the formfield_for_foreignkey() function." | M2M hook should use the same widget precedence shape as FK hook. | Encoded by OBL-001 and audit comparison. |
| E-004 | docs | `ModelAdmin.formfield_for_manytomany(db_field, request, **kwargs)` can be overridden and forwards `**kwargs` to `super()`. | Keep `**kwargs` as the customization channel; do not change signature. | Encoded by OBL-006. |
| E-005 | code/comment | `formfield_for_dbfield()` says passed `**kwargs` override `formfield_overrides` because they are more specific. | A widget supplied through the higher-level path remains present when the M2M helper runs. | Encoded by OBL-005. |
| E-006 | code/frame | Existing M2M code returns `None` for non-auto-created through models. | Preserve the no-formfield behavior before widget selection. | Encoded by OBL-004. |
| E-007 | code/frame | Existing M2M code selects autocomplete, raw-id, or filtered widgets when configured. | Preserve default admin widget selection when no explicit widget exists. | Encoded by OBL-002. |

## Formal Model

The formal model abstracts the audited behavior into `fvk/mini-admin-widget.k` and `fvk/admin-widget-spec.k`.

Inputs:

- `ThroughAuto`: whether the M2M through model is auto-created.
- `MaybeWidget`: either `someWidget(W)` for an explicit caller widget or `noWidget`.
- `AdminOption`: one of `autocompleteOption`, `rawIdOption`, `filteredOption`, or `noAdminWidget`.
- `QuerysetState`: explicit, inferred, or absent queryset state.

Outputs:

- `noFormField` for non-auto-created through models.
- `formField(W, QS)` for auto-created fields, preserving the selected widget `W` and final queryset state `QS`.

The model is property-complete for this issue because it distinguishes the failing pre-fix case (`someWidget(explicitWidget)` plus an admin option producing an admin widget) from the passing V1 case (the resulting widget remains `explicitWidget`).

## Formal Spec English

- CLAIM-001: For every auto-created M2M field, if `widget` is present in `kwargs`, the resulting form field uses that exact widget regardless of autocomplete/raw-id/filter configuration.
- CLAIM-002: For every auto-created M2M field with no explicit widget, autocomplete configuration selects the autocomplete widget.
- CLAIM-003: For every auto-created M2M field with no explicit widget and raw-id configuration, raw-id selects the raw-id widget.
- CLAIM-004: For every auto-created M2M field with no explicit widget and filtered select configuration, filter configuration selects the filtered widget.
- CLAIM-005: For every auto-created M2M field with no explicit widget and no matching admin widget option, Django's field default widget is used.
- CLAIM-006: For every M2M field with a non-auto-created through model, no form field is returned.

## Spec Audit

| Claim | Adequacy result | Rationale |
| --- | --- | --- |
| CLAIM-001 | Pass | Directly matches E-001, E-002, and E-003. |
| CLAIM-002 | Pass | Frame condition from E-007; V1 preserves this behavior when `widget` is absent. |
| CLAIM-003 | Pass | Frame condition from E-007; V1 preserves this behavior when `widget` is absent. |
| CLAIM-004 | Pass | Frame condition from E-007; V1 preserves this behavior when `widget` is absent. |
| CLAIM-005 | Pass | Default field formfield behavior is preserved because no widget is injected. |
| CLAIM-006 | Pass | Frame condition from E-006; the early return remains before widget logic. |

No claim is legacy-derived in a way that contradicts public intent. The only legacy behavior rejected is the pre-fix overwrite described in F-001.

## Public Compatibility Audit

- Changed public symbol: `BaseModelAdmin.formfield_for_manytomany(self, db_field, request, **kwargs)`.
- Signature: unchanged.
- Return shape: unchanged (`None` for non-auto-created through models, otherwise a form field).
- Public override audit: `django.contrib.auth.admin.GroupAdmin.formfield_for_manytomany()` accepts `**kwargs`, modifies `queryset`, and delegates to `super()`. V1 remains compatible.
- Documentation examples: admin reference and multi-database docs override `formfield_for_manytomany()` with `**kwargs` and delegate to `super()`. V1 remains compatible.
- Public caller audit: `formfield_for_dbfield()` still calls the hook with the same positional arguments and expanded `kwargs`.

Compatibility verdict: no source change beyond V1 is required.
