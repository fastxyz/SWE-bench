# Intent Spec

Status: constructed from public evidence only; V1 source is treated as candidate behavior to audit, not as intent.

## Required behavior

1. A Django admin changelist POST that is handled as `list_editable` processing may change database state and must execute its database-changing processing inside a transaction.

2. The transaction must prevent partial database state when an error occurs during list-editable processing: if any changed form's save-related-log sequence raises, earlier writes from the same submitted list-editable batch must not remain committed.

3. Successful list-editable saves must preserve the existing behavior: changed forms are saved, related save hooks run, admin change logs are written, `changecount` counts changed forms, the success message is emitted when `changecount > 0`, and the response redirects to the same changelist URL.

4. Non-list-editable changelist behavior is out of scope for the new transaction requirement and must remain behaviorally unchanged: GET rendering, invalid formset rendering, admin action handling, permission checks, and queryset narrowing for edited object primary keys.

5. The transaction database alias should follow the existing admin write convention: `router.db_for_write(self.model)`, matching add/change/delete admin view transaction handling.

## Domain

The audited path is:

- `request.method == "POST"`;
- `cl.list_editable` is truthy;
- `"_save" in request.POST`;
- `self.has_change_permission(request)` succeeds;
- `formset.is_valid()` is true.

The proof models the post-validation save loop over `N >= 0` changed-form write bundles. Each write bundle abstracts the in-code sequence `save_form()`, `save_model()`, `save_related()`, `construct_change_message()`, and `log_change()`.

## Default-domain assumptions

- Django transaction semantics are all-or-nothing for database writes on the selected connection when an exception escapes the `transaction.atomic()` block.
- The proof is partial correctness: it proves state at normal completion or exceptional rollback, not request termination or database backend liveness.
- External side effects inside custom hooks, such as email or writes to a different database connection, are outside the modeled database transaction unless the application places them on the same connection.
