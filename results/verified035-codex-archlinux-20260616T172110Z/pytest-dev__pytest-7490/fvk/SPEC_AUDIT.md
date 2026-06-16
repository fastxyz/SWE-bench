# Spec Audit

Status: pass, constructed not machine-checked.

| Formal English item | Intent item | Audit |
| --- | --- | --- |
| `dynamic_xfail_body` says body-time dynamic xfail plus failure becomes xfailed with reason `xfail`. | Intent items 1-3 | Pass. This is the public issue's desired behavior. |
| The buggy pytest 6 failure output is not expected behavior. | Intent item 4 | Pass. It is recorded only as Finding FVK-F1. |
| Existing `raises`, `strict`, XPASS, and setup-time `run=False` semantics are reused. | Intent item 5 | Pass. V1 refreshes cache only; existing branches still decide outcomes. |
| `--runxfail` still disables marker-based report rewriting. | Intent item 6 | Pass. Report refresh is below the `runxfail` branch. |
| No public API or hook signature changes. | Intent item 7 | Pass. New symbols are private helpers and a private store key. |

No required behavior is marked fail or ambiguous for this issue's public domain.
