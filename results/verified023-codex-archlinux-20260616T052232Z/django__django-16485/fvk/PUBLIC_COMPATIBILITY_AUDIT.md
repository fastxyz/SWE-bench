# Public Compatibility Audit

Changed public symbol: `django.template.defaultfilters.floatformat`.

## Signature

No signature change. The public callable remains `floatformat(text, arg=-1)`.

## Return Shape

No return type or shape change is introduced. The audited path continues to
return a safe string result through the existing formatting path.

## Public Callers

The repository callsite found outside the implementation is
`django.contrib.humanize.templatetags.humanize`, which calls
`defaultfilters.floatformat(new_value, 1)`. V1 does not change the call
protocol, so this callsite remains compatible.

Template usage documented in `repo/docs/ref/templates/builtins.txt` remains
compatible because numeric precision arguments and `g`/`u` suffix parsing are
not changed by V1.

## Overrides/Subclasses

No subclass or override protocol is involved; `floatformat` is a module-level
template filter function.

Compatibility result: pass.
