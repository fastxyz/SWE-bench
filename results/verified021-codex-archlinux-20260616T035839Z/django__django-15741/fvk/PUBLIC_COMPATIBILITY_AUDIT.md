# Public Compatibility Audit

Status: constructed for FVK audit, not machine-checked.

Changed public symbol: `django.utils.formats.get_format`.

Signature: unchanged. V1 imports `Promise` and adds an internal normalization
step, but does not add parameters, remove parameters, or change defaults.

Return shape: unchanged for concrete string callers. Lazy string callers now
receive the same result family as the corresponding concrete string: cache
value, localized module value, settings value, or arbitrary string fallback.

Known public callers inspected by source search:

| Caller family | Compatibility result |
| --- | --- |
| `django.template.defaultfilters.date` and `time` | Compatible. They continue passing `arg` through `date_format()` / `time_format()` and benefit from helper-level normalization. |
| `django.utils.formats.date_format()` / `time_format()` | Compatible. They still call `get_format(format or "...")`; lazy strings are now accepted. |
| Forms/widgets/i18n views using concrete setting names | Compatible. Concrete strings are unaffected by `isinstance(format_type, Promise)`. |
| `get_format_lazy = lazy(get_format, str, list, tuple)` | Compatible. The wrapped callable signature and possible result classes are unchanged. |

No public override or virtual dispatch compatibility issue was found because
`get_format()` is a module-level helper, not an overridable method.
