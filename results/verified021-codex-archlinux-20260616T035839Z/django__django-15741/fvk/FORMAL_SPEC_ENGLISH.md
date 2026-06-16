# Formal Spec English

Status: constructed for FVK audit, not machine-checked.

The K fragment in `mini-django-formats.k` abstracts the relevant Django
environment into four booleans: whether localization is used, whether the cache
already has a value, whether a localized format module has an attribute for the
normalized string, and whether the normalized string is a registered format
setting. This abstraction preserves the property under audit: whether a lazy
`Promise` reaches string-only lookup paths before becoming a concrete `str`.

Claim C-001: For any string `S`, a localized cache miss with no module value and
no registered setting maps `promiseType(S)` to `rawFormat(S)`. This is the
formal version of `get_format(gettext_lazy("Y-m-d")) == "Y-m-d"` on the issue's
arbitrary-format path.

Claim C-002: For any string `S`, a localized module hit maps `promiseType(S)` to
`moduleValue(S)`, the same abstract result as the concrete string path.

Claim C-003: For any string `S`, a localized module miss with a registered
format setting maps `promiseType(S)` to `settingsValue(S)`.

Claim C-004: For any string `S`, when localization is disabled and `S` is a
registered format setting, `promiseType(S)` maps to `settingsValue(S)`.

Claim C-005: For any string `S`, when localization is disabled and `S` is not a
registered format setting, `promiseType(S)` maps to `rawFormat(S)`.

Claim C-006: For any string `S`, any cache hit maps `promiseType(S)` to
`cacheValue(S)` using the normalized key `S`.

Claim C-007: An out-of-domain `otherType(S)` on a localized module lookup path
still reaches the abstract pre-existing `TypeError`. This is a frame condition:
the proof does not claim broad non-string coercion.
