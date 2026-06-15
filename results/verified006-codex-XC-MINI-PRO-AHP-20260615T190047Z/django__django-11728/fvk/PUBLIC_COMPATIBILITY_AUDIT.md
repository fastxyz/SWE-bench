# Public Compatibility Audit

Status: constructed from in-repo source search.

## Changed symbols

- `django.contrib.admindocs.utils.replace_named_groups(pattern)`
- `django.contrib.admindocs.utils.replace_unnamed_groups(pattern)`

## Compatibility checks

| Item | Result |
|---|---|
| Function signatures | unchanged |
| Return types | unchanged string results |
| Imports | unchanged |
| Public wrapper call order | unchanged in `simplify_regex()` |
| In-repo callsites | `simplify_regex()` remains the only observed production callsite |
| Test files | not modified |

## Conclusion

No compatibility code changes are required beyond the internal loop fixes in
`utils.py`.
