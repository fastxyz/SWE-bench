## Root cause

`django.template.library.parse_bits()` tracked required keyword-only
parameters in `unhandled_kwargs`, excluding keyword-only parameters with
defaults. It also removed required keyword-only parameters from that list as
soon as they were supplied.

The same `unhandled_kwargs` list was then used to decide whether a parsed
keyword was allowed. That made optional keyword-only parameters look
unexpected, and made a repeated required keyword-only argument look unexpected
after its first occurrence had been removed from `unhandled_kwargs`.

## Files changed

`repo/django/template/library.py`

Changed the keyword argument validation in `parse_bits()` so duplicate keyword
arguments are detected before unexpected-keyword validation, and so the
unexpected-keyword check uses the complete `kwonly` parameter list rather than
the required-only `unhandled_kwargs` list. `unhandled_kwargs` is still used for
its original purpose: reporting missing required keyword-only arguments at the
end of parsing.

`reports/baseline_notes.md`

Added this report documenting the investigation and fix.

## Assumptions and alternatives

I assumed the intended behavior is to match Python call semantics for
`simple_tag()` and `inclusion_tag()` helper argument parsing: any declared
keyword-only parameter, including one with a default, may be supplied by
keyword, and repeated keyword names should produce the existing "multiple
values" `TemplateSyntaxError`.

I considered adding a separate collection of allowed keyword names, but the
existing `params` and `kwonly` lists already express that contract. Reusing
`kwonly` keeps the change minimal and avoids altering the missing-required
argument bookkeeping.
