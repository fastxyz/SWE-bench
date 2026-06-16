# Public Evidence Ledger

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| I1 | `benchmark/PROBLEM.md` | "`show_save_as_new` in admin can add without this permission" | Missing add-permission gate is the reported defect. |
| I2 | `benchmark/PROBLEM.md` | "`save_as_new` is a add modification" | The UI action requires add permission. |
| I3 | `benchmark/PROBLEM.md` hints | "Yes, because `Save as New` is a save too (current object)." | The action also requires change permission on the current object. |
| I4 | `repo/django/contrib/admin/templates/admin/submit_line.html` | `{% if show_save_as_new %}... name=\"_saveasnew\"` | The flag controls visible rendering of the submit input. |
| I5 | `repo/django/contrib/admin/options.py` | `render_change_form()` inserts `has_add_permission` and `has_change_permission`. | The relevant permission values are available in context. |
| I6 | `repo/django/contrib/admin/options.py` | `_changeform_view()` checks add permission after `_saveasnew` clears `object_id`. | Backend forged-POST denial already exists and should be preserved. |
