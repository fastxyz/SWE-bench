# Intent Spec

Status: constructed for FVK audit; not machine-checked.

## Public Intent Obligations

- I-1: The issue states that the `add` template filter is unable to
  concatenate a normal string with a lazy string because Python raises
  `TypeError: can only concatenate str (not "__proxy__") to str`, after which
  the filter returns the empty string. Required behavior: this in-domain string
  concatenation must succeed instead of returning `""`.
- I-2: The `add` filter documentation says it first tries to coerce both values
  to integers. If integer coercion fails, it attempts to add the values with
  Python's `+`. If that fails, the result is an empty string. Required behavior:
  lazy text must enter this same documented flow after resolving to text.
- I-3: The same documentation warns that strings coercible to integers are
  summed, not concatenated. Required behavior: numeric lazy text must follow the
  integer-precedence rule after resolution.
- I-4: Django identifies lazy values with `Promise`; `gettext_lazy` and
  `pgettext_lazy` are text promises created by `lazy(..., str)`. Required
  behavior: these text promises are safe to force at template-render time.
- I-5: Existing public behavior for non-lazy operands remains in scope:
  ordinary integer addition, string/list/tuple/date-style `+` fallback, and the
  empty-string fallback for unsupported pairs must continue to use the original
  documented order.

## Domain

The audited function is `django.template.defaultfilters.add(value, arg)`. Its
public template-filter contract accepts arbitrary Python objects and returns
one of:

- an integer sum when both resolved operands can be coerced with `int()`;
- the result of resolved `value + arg` when integer coercion fails and Python
  addition succeeds;
- `""` when both integer coercion and Python addition fail.

The FVK model abstracts arbitrary Python objects as `Value`s with predicates for
`int()` success and native `+` success. It models the reported lazy-string
family as `lazyText(S)`, corresponding to Django `Promise` objects whose
`_delegate_text` marker is true.

