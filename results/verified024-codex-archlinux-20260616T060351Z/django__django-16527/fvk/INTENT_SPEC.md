# Intent Spec

This file is intent-only. It is derived from the public issue, public hints, and
public source names/templates, not from V1 as expected behavior.

## Required Behavior

1. The admin "Save as new" submit control must not be visible to a user who
   lacks add permission for the model.
2. The "Save as new" submit control is add-oriented because it creates a new
   object from the current form.
3. The control still depends on change permission because it is reached from the
   current object's change form.
4. The control should remain unavailable for popups, non-change forms, and
   admins with `save_as` disabled.
5. Server-side permission enforcement for a forged `_saveasnew` POST should
   remain intact.

## In-Domain Context

The submit-row context is in scope when it contains boolean values for
`is_popup`, `has_add_permission`, `has_change_permission`, `change`, and
`save_as`, as supplied by Django admin's change-form rendering path.
