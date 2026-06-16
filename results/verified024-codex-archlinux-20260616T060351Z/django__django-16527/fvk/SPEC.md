# FVK Spec: admin `show_save_as_new`

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

The verified observable is the value of `show_save_as_new` produced by
`django.contrib.admin.templatetags.admin_modify.submit_row(context)`. The
template renders the "Save as new" submit input exactly when this flag is true.

The formal model abstracts the relevant context keys to booleans:

* `is_popup`
* `has_add_permission`
* `has_change_permission`
* `change`
* `save_as`

Other submit-row outputs are frame conditions: this audit does not change their
intended values.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| I1 | prompt | "`show_save_as_new` in admin can add without this permission" | A user lacking add permission must not be shown the "Save as new" control. | Encoded by PO-1 and K claim `NO_ADD`. |
| I2 | prompt | "`save_as_new` is a add modification" | The UI action is add-oriented and requires `has_add_permission`. | Encoded by PO-1 and PO-4. |
| I3 | public hint | "Yes, because `Save as New` is a save too (current object)." | The action still requires permission to change the current object and must only appear on a change form. | Encoded by PO-2 and K claim `NO_CHANGE`. |
| I4 | source: `submit_line.html` | `{% if show_save_as_new %}<input ... name=\"_saveasnew\">{% endif %}` | `show_save_as_new` is the direct rendering guard for the visible submit control. | Encoded by PO-5. |
| I5 | source: `options.py` | `render_change_form()` provides `has_add_permission` and `has_change_permission` in context. | These booleans are available to `submit_row()`; no API/signature change is needed. | Encoded by PO-6. |
| I6 | source: `options.py` | `_changeform_view()` turns `_saveasnew` POSTs into add requests and checks `has_add_permission`. | Forged POSTs without add permission are already denied server-side; the target defect is UI visibility. | Encoded by PO-7. |

## Intended Contract

For every in-domain submit-row context:

```text
show_save_as_new
  == (not is_popup)
     and has_add_permission
     and has_change_permission
     and change
     and save_as
```

Consequences:

* If `has_add_permission` is false, `show_save_as_new` must be false.
* If `has_change_permission` is false, `show_save_as_new` must be false.
* If this is not an existing-object change form (`change` is false), the flag
  must be false.
* If the form is a popup or `save_as` is disabled, the flag must be false.
* If all required conditions hold, the flag must be true.

## Formal Artifacts

* `fvk/mini-submit-row.k` defines the minimal boolean semantics for the
  submit-row flag.
* `fvk/submit-row-spec.k` states K claims for the negative and positive cases.
* `fvk/FORMAL_SPEC_ENGLISH.md` paraphrases each claim.
* `fvk/SPEC_AUDIT.md` compares those paraphrases against this intent spec.
