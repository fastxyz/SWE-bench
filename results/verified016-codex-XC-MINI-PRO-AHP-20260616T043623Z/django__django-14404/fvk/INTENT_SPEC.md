# INTENT SPEC

This file records intent before accepting the candidate implementation as correct.

## Required Behavior

1. `catch_all_view()` must support `FORCE_SCRIPT_NAME`.
2. When it performs an append-slash redirect, the redirect target must include the script name prefix.
3. The correct redirect target for that branch is `request.path + "/"`.
4. The previously observed target `request.path_info + "/"` is the bug, because `path_info` omits the script prefix.
5. URL resolution still needs the slash-appended path that URLconf sees, which is `request.path_info + "/"`.
6. Existing non-redirect behavior remains unchanged: if append-slash is disabled, the captured URL already ends with `/`, the slash-appended resolver lookup fails, or the resolved view opts out of append-slash, the final catch-all raises `Http404`.

## Domain

The in-domain request for the positive branch is an already-authorized admin request reaching `catch_all_view()` with:

- `settings.APPEND_SLASH=True`.
- Captured `url` missing a trailing slash.
- `resolve(request.path_info + "/", urlconf)` succeeds.
- The resolved view has `should_append_slash=True` or no such attribute.

The negative branches cover the complement represented by the conditions in Required Behavior 6.

## Non-Obligations

The issue does not require query-string preservation in this redirect. It names `request.path`, not `request.get_full_path()`, as the intended replacement.
