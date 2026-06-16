# PUBLIC EVIDENCE LEDGER

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| I1 | `benchmark/PROBLEM.md` | "`catch_all_view() does not support FORCE_SCRIPT_NAME.`" | Missing-slash redirects from the admin catch-all must preserve `FORCE_SCRIPT_NAME`. |
| I2 | `benchmark/PROBLEM.md` | "`redirect to '%s/' % request.path_info (script name cut off there) instead of '%s/' % request.path`" | The redirect target must be based on `request.path`, not `request.path_info`. |
| I3 | `repo/tests/requests/tests.py` | Under `FORCE_SCRIPT_NAME='/FORCED_PREFIX/'`, `request.path` is expected to be `'/FORCED_PREFIX/somepath/'`. | `request.path` includes the forced script prefix. |
| C1 | `repo/django/core/handlers/wsgi.py` | `self.path = '%s/%s' % (script_name.rstrip('/'), path_info.replace('/', '', 1))` | The implementation constructs `request.path` from script name plus `path_info`. |
| C2 | `repo/django/contrib/admin/sites.py` | `path = '%s/' % request.path_info`; `match = resolve(path, urlconf)` | The resolver candidate is script-stripped and slash-appended. |
| C3 | `repo/django/contrib/admin/sites.py` | `if getattr(match.func, 'should_append_slash', True)` | A successful resolver match redirects only when the target view allows append-slash. |
