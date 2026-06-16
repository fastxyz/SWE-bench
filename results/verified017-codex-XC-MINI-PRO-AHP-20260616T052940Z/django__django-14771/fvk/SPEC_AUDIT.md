# Spec Audit

Status: constructed; not machine-checked.

| Claim | Intent Match | Audit |
| --- | --- | --- |
| C1 script relaunch | Pass | Directly covers the reported `python -X utf8 manage.py runserver` path from E1-E3. |
| C2 module relaunch | Pass | The issue title is about the autoreloader generally, and this branch launches through `sys.executable`; preserving interpreter options is required by E1. |
| C3 script-entrypoint fallback | Pass | This branch also launches through `sys.executable`; adding `-X` replay follows E1 while preserving existing branch shape from E6. |
| C4 flag xoption formatting | Pass with named assumption | The issue does not dictate token spelling. The spec uses the default-domain assumption that attached CPython short-option arguments such as `-Xutf8` are equivalent to `-X utf8`. |
| C5 value xoption formatting | Pass | E1 and E4 require preserving the whole `-X` option, not only option names; `name=value` options must carry their value. |
| C6 no xoption ledger | Pass | No public evidence requires replay where the interpreter exposes no `_xoptions` source. |
| C7 direct `.exe` fallback | Pass | E2's reproduction uses `python -X ... manage.py`, not a direct entrypoint shim. Existing tests/source identify this as an intentional non-`sys.executable` path. |

No claim contradicts the public issue intent. No no-change conclusion depends on
a SUSPECT legacy behavior.
