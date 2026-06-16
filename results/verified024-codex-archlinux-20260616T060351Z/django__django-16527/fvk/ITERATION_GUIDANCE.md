# Iteration Guidance

Status: V1 stands.

## Source Decision

Do not change the source beyond V1. The audit found that the one-line condition
change in `admin_modify.py` discharges the add-permission obligation while
preserving the current-object change requirement.

## Recommended Future Checks

If test authoring is available in a normal development environment, add or keep
coverage for:

* `show_save_as_new` is false when `has_add_permission` is false, even if
  `has_change_permission`, `change`, and `save_as` are true.
* `show_save_as_new` is false when `has_change_permission` is false.
* `show_save_as_new` is true when all required conditions hold.
* Forged `_saveasnew` POSTs without add permission are rejected by the backend.

Do not remove tests based on this FVK pass alone. The proof is constructed, not
machine-checked.

## If Machine Checking Fails

First repair K syntax or version-specific command details in the FVK artifacts.
Only revisit production source if the semantic claim fails, not merely because a
tool rejects the handwritten mini-K syntax.

## Residual Risk

The proof covers the visible submit-row flag and the source-inspected backend
guard. It does not prove all admin change-form behavior, template inheritance
customizations, browser interactions, or termination/performance properties.
