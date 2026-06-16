# Baseline Notes

## Root cause

`AdminSite.catch_all_view()` handled `APPEND_SLASH` redirects by building the
target URL with `"%s/" % request.path`. `request.path` excludes the query
string, so a request such as `/admin/auth/foo?id=123` redirected to
`/admin/auth/foo/` instead of preserving `?id=123`.

## Changed files

`repo/django/contrib/admin/sites.py`

Replaced the manual path concatenation in `AdminSite.catch_all_view()` with
`request.get_full_path(force_append_slash=True)`. This is Django's existing
request API for constructing a path with the current query string preserved
while appending a trailing slash before the query component.

## Assumptions and alternatives

I assumed the intended behavior is the same as Django's other `APPEND_SLASH`
redirect paths: append the slash to the path, preserve the existing query
string, and continue respecting `should_append_slash`.

I considered manually adding `request.META["QUERY_STRING"]` to the existing
redirect, but rejected that because `get_full_path()` already handles URI
escaping and query-string preservation consistently. I also considered changing
similar redirects outside the admin app, but rejected that as outside the
reported regression and unnecessary for the targeted fix.
