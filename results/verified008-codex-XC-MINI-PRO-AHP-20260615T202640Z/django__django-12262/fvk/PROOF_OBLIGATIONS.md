# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Optional Keyword-Only Parameters Are Legal

For any keyword token `p=value`, if `p in kwonly`, `p not in seen`, and no prior
error exists, `parse_bits()` must not classify `p` as unexpected solely because
`p` has a default and is absent from `required_kwonly`.

Public evidence: E1, E2, E5, E6.

Formal claim: `ALLOW-DEFAULT-KWONLY`.

V1 status: discharged. The unexpected-keyword predicate checks `param not in
kwonly`, not `param not in unhandled_kwargs`.

## PO-2: Duplicate Keyword Names Take Precedence

For repeated keyword tokens with the same legal keyword-only name, the second
token must produce the "multiple values for keyword argument" `TemplateSyntaxError`,
not the "unexpected keyword argument" error.

Public evidence: E3.

Formal claim: `DUPLICATE-KWONLY`.

V1 status: discharged. `param in kwargs` is checked before unexpected-keyword
validation.

## PO-3: Unknown Keywords Stay Unexpected

For a keyword token `p=value` where `p not in params`, `p not in kwonly`, and
`varkw is None`, parsing must still raise the existing unexpected-keyword
`TemplateSyntaxError`.

Public evidence: E6, E7.

Formal claim: `UNKNOWN-STILL-UNEXPECTED`.

V1 status: discharged. The V1 change broadens only the keyword-only allowed set;
it does not legalize names outside `params`, `kwonly`, and `**kwargs`.

## PO-4: Missing Required Keyword-Only Parameters Stay Missing

For a required keyword-only parameter `p` where `p in kwonly` and `p` is absent
from `kwonly_defaults`, parsing must still report `p` in the existing missing
argument error if no keyword token supplies it.

Public evidence: E5, E7.

Formal claim: `MISSING-REQUIRED-KWONLY`.

V1 status: discharged. `unhandled_kwargs` remains the required-only list and is
still used for the final missing-argument check.

## PO-5: Shared Helper Compatibility

The behavior change must reach `simple_tag()` and `inclusion_tag()` without
requiring public signature changes or callsite rewrites.

Public evidence: E4, E8.

Formal claim: compatibility audit, no K claim required beyond the shared
`parse_bits()` claims.

V1 status: discharged. The fix is entirely inside `parse_bits()` and all public
callers pass the same inputs as before.

## PO-6: Adjacent Positional-Plus-Keyword Duplicate Case

There is an adjacent Python-call-semantics question: a positional argument may
consume a parameter name and a later keyword token may use the same name. That is
not the duplicate keyword-token case reported in E3.

Public evidence: E6 provides weak "Like in Python" support, but the issue text
does not request a broader compile-time diagnostic change, and no FVK conclusion
for django__django-12262 depends on this behavior.

Formal claim: none in this run.

V1 status: explicitly unclaimed. Treat as a future clarification/test gap, not a
required source change for this issue.
