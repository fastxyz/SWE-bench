# Public Compatibility Audit

| Surface | Compatibility question | Result |
| --- | --- | --- |
| `PYLINTHOME` environment variable | Does an explicit override still win exactly? | Yes; unchanged and covered by PO-1. |
| `PYLINT_HOME` module constant | Does the default change intentionally? | Yes; this is the issue fix. |
| `_get_pdata_path(base, recurs)` | Are stats filenames still formed the same way under the selected directory? | Yes; basename sanitization and suffix are unchanged. |
| `load_results()` / `save_results()` | Is the pickle format changed? | No. |
| Public function signatures | Were public callable signatures changed? | No. |
| Documentation | Does public FAQ match the new behavior? | Failed in V1; fixed in V2. |
| Tests | Were tests modified? | No. |

