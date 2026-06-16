# Spec Adequacy Audit

Status: pass.

| Formal clause | Intent clause | Audit |
|---|---|---|
| `SYMBOL-PLAIN` returns `MI(base, bold)` for empty script lists. | Plain symbols such as `x` remain `<mi>x</mi>` and bold matrix style remains compatible. | Pass |
| `SYMBOL-SUB` returns `MSUB(MI(base), join(subs))` directly. | Corrected issue markup removes outer `mi` and uses top-level `msub`. | Pass |
| `SYMBOL-SUP` returns `MSUP(...)` directly. | Same wrapper bug mechanism applies to scripted presentation nodes as a family. | Pass |
| `SYMBOL-SUBSUP` returns `MSUBSUP(...)` directly. | Same wrapper bug mechanism applies when both script kinds are present. | Pass |
| `SYMBOL-X2` returns `MSUB(MI("x"), MI("2"))`. | `x2` remains subscripted and uses the corrected shape. | Pass |
| No scripted claim preserves old top-level `MI`. | Public issue says old top-level `mi` wrapper is wrong. | Pass |
| Old tests expecting top-level `mi` for scripted symbols are not preserved. | FVK marks tests encoding the reported bug as SUSPECT. | Pass |

No required behavior is marked fail or ambiguous.
