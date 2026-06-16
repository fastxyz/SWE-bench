# Baseline Notes

## Root cause

The admin submit-row context computed `show_save_as_new` without checking
`has_add_permission`. `Save as new` creates a new model instance from the
change form, so offering that button to a user who can change the current
object but cannot add new objects exposed an add-oriented action in the UI.

The change-form POST path already treats `_saveasnew` as an add request by
clearing `object_id`, which then requires `has_add_permission` before saving.
The bug is therefore in the button visibility condition rather than in the
server-side permission check.

## Files changed

* `repo/django/contrib/admin/templatetags/admin_modify.py`
  * Added `has_add_permission` to the `show_save_as_new` condition so the
    button is shown only when the user can both change the current object and
    add a new object.

## Assumptions and alternatives considered

* I assumed `Save as new` should continue to require change permission because
  it starts from an existing object's change form and submits that object's
  editable data.
* I considered checking only `has_add_permission`, but rejected it because that
  would let users without change permission see a save control on an existing
  object's form.
* I considered changing `ModelAdmin._changeform_view()`, but rejected it because
  that path already denies `_saveasnew` POSTs without add permission.
