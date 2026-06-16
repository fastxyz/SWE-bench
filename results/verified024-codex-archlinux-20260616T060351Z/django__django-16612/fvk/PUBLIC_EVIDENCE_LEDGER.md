# PUBLIC EVIDENCE LEDGER

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "AdminSite.catch_all_view() drops query string in redirects" | Preserve query strings in admin catch-all redirects. |
| E2 | `benchmark/PROBLEM.md` | Provided URL `/admin/auth/foo?id=123`; expected redirect `/admin/auth/foo/?id=123`; actual redirect `/admin/auth/foo/`. | Put the slash before the query and keep the query. |
| E3 | `benchmark/PROBLEM.md` | "with settings.APPEND_SLASH = True" | Scope the redirect behavior to APPEND_SLASH handling. |
| E4 | `benchmark/PROBLEM.md` hint | "Using get_full_path() should fix the issue" and replacement with `request.get_full_path(force_append_slash=True)`. | Use the request helper that preserves query strings while forcing the slash. |
| E5 | `repo/django/contrib/admin/sites.py` | `resolve("%s/" % request.path_info, urlconf)` and `getattr(match.func, "should_append_slash", True)`. | Preserve existing redirect eligibility gates. |
| E6 | `repo/django/http/request.py` | `_get_full_path()` appends `?` plus `QUERY_STRING` when non-empty. | The helper's contract provides query preservation. |
