# Findings

Status: constructed, not machine-checked.

## F-1: V1 Fixes Optional Keyword-Only Defaults

Input shape:

```python
@register.simple_tag
def hello(*, greeting='hello'):
    ...
```

Template:

```django
{% hello greeting='hi' %}
```

Pre-V1 observed behavior from the issue: `TemplateSyntaxError("'hello' received
unexpected keyword argument 'greeting'")`.

Expected behavior from E1, E2, and E5: `greeting` is a declared keyword-only
parameter and must be accepted even though it has a default.

V1 audit: pass. PO-1 is discharged because the unexpected-keyword check now uses
the complete `kwonly` list.

## F-2: V1 Fixes Duplicate Keyword-Only Error Priority

Input shape:

```python
@register.simple_tag
def hi(*, greeting):
    ...
```

Template:

```django
{% hi greeting='hi' greeting='hello' %}
```

Pre-V1 observed behavior from the issue: `TemplateSyntaxError("'hi' received
unexpected keyword argument 'greeting'")`.

Expected behavior from E3: `TemplateSyntaxError("'hi' received multiple values
for keyword argument 'greeting'")`.

V1 audit: pass. PO-2 is discharged because duplicate keyword names are checked
before unexpected-keyword validation.

## F-3: Unknown and Missing Errors Remain Intact

Input shapes:

- Unknown keyword with no `**kwargs`: `{% tag valid=1 unknown=2 %}`.
- Missing required keyword-only parameter: `def tag(*, required): ...` with
  `{% tag %}`.

Expected behavior from E6 and E7: unknown keyword names remain unexpected, and
missing required keyword-only parameters remain missing.

V1 audit: pass. PO-3 and PO-4 are discharged. The fix does not alter final
missing-argument bookkeeping.

## F-4: Shared Helper Coverage

Input shape: the same keyword-only cases through `simple_tag()` and
`inclusion_tag()`.

Expected behavior from E4: both helpers share the same repair.

V1 audit: pass. PO-5 is discharged because `simple_tag()`, `inclusion_tag()`,
and the admin inclusion wrapper all call `parse_bits()` with the same signature.

## F-5: Adjacent Duplicate Semantics Are Unclaimed

Input shape:

```django
{% some_tag 1 same_name=2 %}
```

where the first positional token consumed parameter `same_name`.

Observed from code inspection: this run does not prove or change that adjacent
case. The public issue's duplicate example is two keyword tokens with the same
name, and the source change for django__django-12262 does not rely on the
broader behavior.

Classification: test gap / underspecified intent outside this issue's required
repair. If Django wants compile-time Python-call-semantics diagnostics for this
case, that should be handled as a separate obligation.

Recommended action for this task: no source change.

## Proof-Derived Findings From `/verify`

No code bug remains against PO-1 through PO-5. The proof is constructed, not
machine-checked, so no tests should be removed based on it. F-5 remains a
separate future clarification, not a blocker for confirming V1 on the reported
issue.
