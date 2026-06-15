# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Intent item | Verdict | Notes |
| --- | --- | --- | --- |
| `ARGS-DROP-NONE` | E3, E4 | Pass | Public hint explicitly says to discard `None` arguments and gives positional template syntax as a desired use case. |
| `KWARGS-DROP-NONE` | E1, E2, E3, E6 | Pass | `translate_url()` sends `resolve()` kwargs to `reverse()`; absent optional named captures are represented as `None`. |
| `OPTIONAL-KWARGS` | E1, E2, E8 | Pass | The shorter candidate must be selected when the optional named capture is absent. |
| `OPTIONAL-ARGS` | E3, E4 | Pass | Positional `None` is intentionally treated as omitted. |
| `EMPTY-STRING-PRESERVED` | E5 | Pass | The filter is identity-based on `None`, so empty string remains present. |
| Mixed args/kwargs frame condition | E5 plus existing API behavior | Pass | The existing check remains before normalization. |
| Public API compatibility | E6, E7 | Pass | No signature, return-type, or call protocol change. |

No formal-English claim is candidate-derived without public evidence. The proof is still labeled constructed, not machine-checked.

