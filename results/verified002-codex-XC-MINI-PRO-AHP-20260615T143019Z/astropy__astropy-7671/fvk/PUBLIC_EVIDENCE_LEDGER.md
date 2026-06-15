# Public Evidence Ledger

| ID | Source | Evidence | Obligation |
|---|---|---|---|
| E1 | `benchmark/PROBLEM.md` | `minversion('numpy', '1.14dev')` raises `TypeError` | Remove the exception for this class of version comparisons. |
| E2 | `benchmark/PROBLEM.md` | `LooseVersion('1.14.3') >= LooseVersion('1.14dev')` raises `TypeError` | The failure mechanism is `LooseVersion` comparing numeric and suffix tokens. |
| E3 | `benchmark/PROBLEM.md` | `parse_version('1.14.3') >= parse_version('1.14dev')` is `True` | The reported comparison should evaluate to `True`. |
| E4 | Public hint | "put the regex back in" and "don't want to go back to `pkg_resources`" | Normalize before `LooseVersion`; do not reintroduce `pkg_resources`. |
| E5 | `minversion` docstring | `inclusive` selects inclusive `>=` or strict `>` minimum behavior | Preserve inclusive/exclusive branch semantics. |
| E6 | `minversion` docstring/source | module object or string accepted; import failure returns `False`; invalid module raises `ValueError` | Preserve public API and non-comparison control flow. |
| E7 | In-repo tests/calls | numeric versions such as `0.12`, `0.12.0.dev`, `1.2rc1`, `1.14.2` | Numeric release strings with suffixes are the relevant public domain. |

