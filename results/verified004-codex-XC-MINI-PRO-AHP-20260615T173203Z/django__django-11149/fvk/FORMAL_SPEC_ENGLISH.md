# Formal Spec English

This file paraphrases each nontrivial K claim in `fvk/admin-inline-permissions-spec.k`.

## VIEW-OR-CHANGE-CAN-VIEW

For an auto-created many-to-many intermediary inline, a user may view the inline if the target model grants either view permission or change permission.

## WRITE-FOLLOWS-TARGET-CHANGE

For an auto-created many-to-many intermediary inline, write permission for relationship rows is exactly target model change permission.

## VIEW-ONLY-WRITE-FALSE

For a target-view-only user, where target view is true and target change is false, add/change/delete of auto-created many-to-many relationship rows are not permitted.

## VIEW-ONLY-POST-PRESERVES

If write permission is false, applying a submitted inline formset preserves the original relationship state, regardless of what relationship state the submitted data requested.

## TARGET-CHANGE-POST-APPLIES

If write permission is true, applying a submitted inline formset uses the submitted relationship state.

## TARGET-CHANGE-WRITE-TRUE

If target model change permission is true, write permission for the auto-created many-to-many relationship rows is true.
