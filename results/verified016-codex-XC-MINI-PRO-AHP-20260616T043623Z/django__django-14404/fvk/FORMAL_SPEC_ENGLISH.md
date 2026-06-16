# FORMAL SPEC ENGLISH

Status: English paraphrase of the K claims.

## CLAIM-REDIRECT

For any symbolic `PATHINFO` and `PATH`, if append-slash is enabled, the captured URL does not already end in `/`, and resolving `PATHINFO + "/"` yields a view that allows append-slash, `catch_all_view()` returns a redirect to `PATH + "/"`.

## CLAIM-FORCE-SCRIPT-NAME-WITNESS

For the concrete witness with `PATHINFO="/admin/auth/user"` and `PATH="/script/admin/auth/user"`, the successful append-slash branch returns a redirect to `"/script/admin/auth/user/"`.

## CLAIM-NO-REDIRECT-APPEND-FALSE

If append-slash is disabled, `catch_all_view()` raises `Http404` for this local branch model.

## CLAIM-NO-REDIRECT-URL-SLASH

If the captured URL already ends in `/`, `catch_all_view()` raises `Http404` for this local branch model.

## CLAIM-NO-REDIRECT-RESOLVER404

If resolving `PATHINFO + "/"` fails, `catch_all_view()` raises `Http404`.

## CLAIM-NO-REDIRECT-SHOULD-NOT-APPEND

If resolving `PATHINFO + "/"` succeeds but the resolved view has `should_append_slash=False`, `catch_all_view()` raises `Http404`.
