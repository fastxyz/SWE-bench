# Spec Audit

| Formal English item | Intent match | Notes |
| --- | --- | --- |
| `PYLINTHOME-OVERRIDE` | Pass | Directly required by public hint. |
| `DEFAULT-XDG-CACHE` | Pass | Satisfies XDG cache placement when a valid cache base is configured. |
| `DEFAULT-HOME-CACHE` | Pass | Satisfies XDG default cache placement and avoids `~/.pylint.d`. |
| `DEFAULT-NO-HOME` | Pass | Preserves the legacy current-directory fallback only when no home is discoverable. |
| `MAKEDIRS-MISSING` | Pass | Required because XDG defaults can be nested. |
| `NO-MAKEDIRS-EXISTING` | Pass | Frame condition; no public behavior requires recreating an existing directory. |
| Public FAQ alignment | Failed in V1, pass in V2 | F-004 prompted the V2 `doc/faq.rst` edit. |

