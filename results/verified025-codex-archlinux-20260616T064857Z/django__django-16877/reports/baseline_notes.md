# Baseline Notes

## Root cause

Django's built-in template filters included `safe` for a single value and
`safeseq` for applying `safe` to each item in a sequence, but there was no
corresponding sequence filter for `escape`. In an `{% autoescape off %}` block,
`join` joins sequence items without escaping them, then marks the joined result
safe. This means `{{ some_list|join:"," }}` can emit unescaped HTML, and there
was no built-in way to escape each item before joining without writing custom
template logic.

## Files changed

`repo/django/template/defaultfilters.py`

Added a built-in `escapeseq` filter next to `safeseq`. The filter returns a list
where each sequence member has been passed through `conditional_escape()`, which
matches the semantics of Django's existing `escape` filter: unsafe values are
HTML-escaped and marked safe, while values that already provide `__html__()` are
not escaped a second time. Registering it with `is_safe=True` follows the local
pattern used by `safeseq` and the existing HTML string filters.

## Assumptions and alternatives

I assumed `escapeseq` should mirror the existing `escape` filter, not
`force_escape`, so already-safe values should not be double-escaped. I rejected
using `django.utils.html.escape()` directly because that would make `escapeseq`
behave more like `force_escape` than `escape`.

I assumed the new filter should preserve `safeseq`'s simple sequence behavior and
fail naturally for non-iterable inputs rather than adding special error handling.
That keeps the change minimal and consistent with the nearby filter.

I did not modify tests or run the test suite because the benchmark instructions
explicitly prohibit test changes and code execution.
