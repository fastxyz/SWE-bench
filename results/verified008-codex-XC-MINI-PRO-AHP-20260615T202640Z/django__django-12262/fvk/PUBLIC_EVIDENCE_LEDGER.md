# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Custom template tags raise TemplateSyntaxError when keyword-only arguments with defaults are provided." | Optional keyword-only parameters are valid keywords. |
| E2 | `benchmark/PROBLEM.md` | `def hello(*, greeting='hello')` and `{% hello greeting='hi' %}` should not raise unexpected keyword. | `kwonly` membership, not required-only membership, determines keyword legality. |
| E3 | `benchmark/PROBLEM.md` | Duplicate `greeting` should raise "received multiple values for keyword argument 'greeting'". | Duplicate keyword detection has priority over unexpected-keyword reporting. |
| E4 | `benchmark/PROBLEM.md` | "Same goes for inclusion tags (is the same code)." | The shared helper fix must cover `inclusion_tag()`. |
| E5 | `repo/docs/releases/2.0.txt:318` | "Custom template tags may now accept keyword-only arguments." | Keyword-only parameters are public supported API for custom tags. |
| E6 | `repo/docs/howto/custom-template-tags.txt:467-480`, `:613-626` | `simple_tag` and `inclusion_tag` functions may accept keyword arguments, and keywords use `=` after positional arguments. | Legal declared keywords must be accepted and positional-after-keyword ordering remains enforced. |
| E7 | `repo/tests/template_tests/test_custom.py:92-103`, `:201-217` | Existing errors for unknown keywords, missing arguments, and duplicate `**kwargs` keyword names. | Preserve existing diagnostics outside the reported keyword-only bug. |
| E8 | `repo/django/template/library.py:119-154`, `repo/django/contrib/admin/templatetags/base.py:16-18` | All helper paths call `parse_bits()` with `kwonly` and `kwonly_defaults`. | A local helper change covers all relevant call paths without signature changes. |
