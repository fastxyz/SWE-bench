# Public Compatibility Audit

Status: constructed from source inspection only; no code executed.

Changed public symbol: `django.template.defaultfilters.floatformat`.

Compatibility results:

* Signature unchanged: `floatformat(text, arg=-1)`.
* Decorator unchanged: `@register.filter(is_safe=True)`.
* Return protocol unchanged for normal formatting: result still flows through
  `mark_safe(formats.number_format(...))`.
* Suffix parsing for `g`, `u`, `gu`, and `ug` unchanged.
* Non-Decimal conversion path unchanged.
* Known in-repository caller `django.contrib.humanize.templatetags.humanize`
  calls `defaultfilters.floatformat(new_value, 1)` with non-Decimal magnitude
  values and is unaffected by the Decimal-specific branch.
* No subclass or override compatibility issue applies because this is a module
  function, not a virtual method.

Compatibility note:

V1 returns `str(Decimal)` rather than `repr(Decimal)` if a Decimal value reaches
the invalid-argument fallback. No public evidence found requires exposing
`Decimal('...')` in template output, and the docs frame `floatformat` output as
numeric display. This is therefore not a blocking compatibility issue.
