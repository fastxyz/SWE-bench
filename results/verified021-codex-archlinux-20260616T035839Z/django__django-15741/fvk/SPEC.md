# FVK Specification

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 source change in
`repo/django/utils/formats.py:get_format()`. The target behavior is the public
issue `django__django-15741`: `get_format()` should accept lazy string
parameters, including the date-template-filter example
`some_date|date:_("Y-m-d")`.

No tests, Python code, or K tooling were executed.

## Intent Summary

The intended domain for this issue is `format_type` values that are either
concrete strings or Django lazy `Promise` objects that evaluate to strings.
Within that domain, `get_format(Promise(S), ...)` must behave like
`get_format(S, ...)`.

The proof does not claim support for arbitrary non-string objects. This matches
the existing docstring, which describes `format_type` as a format name string,
and the V1 baseline decision to avoid broad `str()` coercion.

## Public Evidence Ledger

| ID | Evidence | Obligation |
| --- | --- | --- |
| E-001 | "`get_format` should allow lazy parameter" | Lazy string `format_type` values are in-domain. |
| E-002 | "`some_date|date:_('Y-m-d')`" | Lazy arbitrary custom format strings must return their evaluated format string when no registered format is found. |
| E-003 | "`TypeError: getattr(): attribute name must be string`" | Lazy objects must not reach `getattr()` as attribute names. |
| E-004 | "`possibly others are affected too`" | The repair belongs in `get_format()`, not only the date filter. |
| E-005 | `get_format()` docstring: `format_type` is a format name such as `'DATE_FORMAT'` | Registered format settings and custom module attributes remain string-name lookups. |

The standalone ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

## Formal Domain Model

The K fragment uses `FType` values:

- `strType(S)` for concrete string `format_type` values.
- `promiseType(S)` for Django lazy `Promise` values whose `str()` result is
  `S`.
- `otherType(S)` for out-of-domain non-Promise values, used only for the frame
  condition that V1 does not prove broad coercion.

The environment is abstracted into branch booleans:

- `USE_L10N`: whether localized module lookup is enabled.
- `CACHE_HIT`: whether the normalized `(format_type, lang)` key is cached.
- `MODULE_HAS`: whether a localized format module has the normalized name.
- `IN_FORMAT_SETTINGS`: whether the normalized name is one of the registered
  format settings.

This model intentionally abstracts away import mechanics and concrete setting
values while preserving the audited property: every in-domain `Promise` reaches
cache/module/settings/fallback paths only after normalization to its string.

## Contract

For every string `S` and every environment branch represented above:

1. `get_format(promiseType(S), ...)` first normalizes to `strType(S)`.
2. Cache hits use the normalized key `S`.
3. Localized module lookup receives `S`, never `promiseType(S)`.
4. Settings lookup receives `S`, never `promiseType(S)`.
5. If no module/settings value exists, the arbitrary-format fallback returns
   `S`.

Frame condition: inputs outside the issue domain, such as arbitrary non-Promise
objects, are not newly specified as supported. V1 only normalizes
`Promise` values.

## Formal Artifacts

- `fvk/mini-django-formats.k`: minimal K-style semantics for the relevant
  `get_format()` branch structure.
- `fvk/get-format-spec.k`: K-style claims for lazy string behavior on cache,
  module, settings, and arbitrary fallback paths.
- `fvk/FORMAL_SPEC_ENGLISH.md`: English paraphrase of each claim.
- `fvk/SPEC_AUDIT.md`: adequacy check comparing the formal claims to public
  intent.
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`: callsite/API compatibility check.

Machine-check commands to run later, not executed in this session:

```sh
cd fvk
kompile mini-django-formats.k --backend haskell
kast --backend haskell get-format-spec.k
kprove get-format-spec.k
```

Expected result after a successful machine check: `#Top` for all claims.
