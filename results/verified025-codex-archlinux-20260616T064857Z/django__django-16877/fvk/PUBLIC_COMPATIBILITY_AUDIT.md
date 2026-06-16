# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed public surface

`django.template.defaultfilters.escapeseq` is a new built-in template filter.

## Compatibility checks

| Surface | Compatibility result |
| --- | --- |
| Existing filter names | Additive only. No existing filter is renamed or replaced. |
| Existing filter signatures | No existing filter signature is changed. |
| `join` behavior | Unchanged. The fix prepares sequence items before `join`; it does not alter separator or autoescape rules. |
| `escape` / `force_escape` behavior | Unchanged. `escapeseq` delegates to existing `conditional_escape()` semantics. |
| `safeseq` behavior | Unchanged. `escapeseq` is adjacent and analogous but does not modify `safeseq`. |
| Template docs | V1 had no public docs entry for the new built-in filter. V2 adds one in `docs/ref/templates/builtins.txt`. |

## Verdict

No backward-incompatible API change was found. The only compatibility issue was
discoverability/documentation for the new public filter, fixed by adding the
docs entry.
