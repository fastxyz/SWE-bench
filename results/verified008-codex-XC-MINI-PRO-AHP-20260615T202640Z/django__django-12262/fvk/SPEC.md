# FVK Spec: django__django-12262

Status: constructed, not machine-checked.

## Scope

The audited unit is `django.template.library.parse_bits()` as called by
`Library.simple_tag()`, `Library.inclusion_tag()`, and
`django.contrib.admin.templatetags.base.InclusionAdminNode`.

The observable behavior under audit is compile-time argument validation for
template tag helper keyword arguments. Rendering, filter expression resolution,
and template output generation are outside this proof slice.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "Custom template tags raise TemplateSyntaxError when keyword-only arguments with defaults are provided." | Supplying a declared keyword-only parameter with a default must be accepted, not reported as unexpected. | Encoded in PO-1 and claim `ALLOW-DEFAULT-KWONLY`. |
| E2 | prompt | `def hello(*, greeting='hello')` with `{% hello greeting='hi' %}` raises unexpected keyword. | For `greeting in kwonly`, `greeting not in required_kwonly` is still a legal keyword. | Encoded in PO-1. |
| E3 | prompt | Duplicate `{% hi greeting='hi' greeting='hello' %}` should raise "'hi' received multiple values for keyword argument 'greeting'". | Duplicate keyword names must be detected before a later unexpected-keyword check can mask them. | Encoded in PO-2 and claim `DUPLICATE-KWONLY`. |
| E4 | prompt | "Same goes for inclusion tags (is the same code)." | The repair must cover both `simple_tag()` and `inclusion_tag()` through their shared helper. | Encoded in PO-5. |
| E5 | docs | `repo/docs/releases/2.0.txt:318`: "Custom template tags may now accept keyword-only arguments." | Declared keyword-only arguments are part of the public supported signature surface. | Encoded in PO-1 and PO-4. |
| E6 | docs | `repo/docs/howto/custom-template-tags.txt:467-480` and `:613-626`: tag functions may accept keyword arguments and keyword values use `=` after positional arguments. | Keyword parsing should validate legal keyword names, preserve positional-before-keyword ordering, and reject illegal names. | Encoded in PO-1, PO-3, and frame conditions. |
| E7 | public tests | Existing tests expect unknown keywords to remain unexpected and missing required keyword-only arguments to remain missing. | The fix must not make unknown names legal or drop required keyword-only missing diagnostics. | Encoded in PO-3 and PO-4. |
| E8 | implementation | All relevant callers pass `params`, `varargs`, `varkw`, `defaults`, `kwonly`, and `kwonly_defaults` into `parse_bits()`. | A fix in `parse_bits()` covers the helpers without signature changes. | Encoded in PO-5. |

## Definitions

Let:

- `params` be the list of declared positional-or-keyword parameters, after
  removing the leading `context` parameter when `takes_context=True`.
- `kwonly` be the complete list of declared keyword-only parameter names.
- `kwonly_defaults` be the dictionary of keyword-only defaults, or `None`.
- `required_kwonly = [p for p in kwonly if p not in kwonly_defaults]`, with all
  keyword-only parameters required when `kwonly_defaults is None`.
- `seen` be the set of keyword names already recorded in `kwargs`.
- `legal_keyword(p) = p in params or p in kwonly or varkw is not None`.

## Required Behavior

For every token bit that `token_kwargs([bit], parser)` parses as keyword
`param=value`:

1. If `param in seen`, parsing raises
   `TemplateSyntaxError("'<name>' received multiple values for keyword argument '<param>'")`.
2. Otherwise, if `not legal_keyword(param)`, parsing raises
   `TemplateSyntaxError("'<name>' received unexpected keyword argument '<param>'")`.
3. Otherwise, the keyword is recorded in `kwargs`.
4. If `param` was in the unhandled positional list, that positional name is
   consumed. If `param` was in `required_kwonly`, that required keyword-only
   obligation is consumed.

After all bits are consumed:

1. Positional defaults may satisfy trailing positional parameters as before.
2. Any remaining `params` or `required_kwonly` names cause the existing missing
   argument `TemplateSyntaxError`.
3. If no error occurred, `parse_bits()` returns the parsed positional `args` and
   keyword `kwargs`.

## Frame Conditions

- The public signature of `parse_bits()` is unchanged.
- `simple_tag()` and `inclusion_tag()` continue to call the same helper.
- Unknown keyword arguments remain errors when no `**kwargs` parameter exists.
- Missing required keyword-only arguments remain errors.
- The FVK proof covers repeated keyword tokens. It does not claim that this issue
  requires changing the adjacent positional-plus-keyword duplicate case.
