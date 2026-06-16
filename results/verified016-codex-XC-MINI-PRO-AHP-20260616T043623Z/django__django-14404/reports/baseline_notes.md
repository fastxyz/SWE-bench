# Baseline Notes

## Root cause

`AdminSite.catch_all_view()` handles admin URLs that are missing a trailing slash when `APPEND_SLASH` is enabled. It builds a slash-appended path from `request.path_info` and uses that path both to resolve the candidate URL and as the redirect target.

`request.path_info` intentionally excludes `SCRIPT_NAME`, including the prefix configured by `FORCE_SCRIPT_NAME`. That makes it correct for URL resolver lookup, but incorrect as the client-visible redirect URL. With a forced script name, the redirect strips the deployment prefix.

## Changed files

`repo/django/contrib/admin/sites.py`

Changed the successful append-slash redirect in `AdminSite.catch_all_view()` to redirect to `request.path` plus `/` instead of the resolver path derived from `request.path_info`. `request.path` includes the script prefix, so redirects preserve `FORCE_SCRIPT_NAME` while the existing resolver check continues to use `path_info`.

## Assumptions and alternatives considered

I assumed the intended behavior is to preserve the script prefix only in the redirect target, not in the resolver input. This matches Django's request model: `path_info` is the URL path seen by URLconf resolution, while `path` is the externally visible request path.

I considered replacing the local logic with `request.get_full_path(force_append_slash=True)`, which would also include the script prefix and preserve query strings. I rejected that as a broader behavior change because the existing code redirects with only the path component, and the reported issue specifically identifies `request.path` as the missing-script-name replacement.

I also considered changing the resolver candidate to use `request.path`, but rejected it because URLconf resolution should not include `SCRIPT_NAME`; doing so would make mounted deployments fail to find otherwise valid admin URLs.
