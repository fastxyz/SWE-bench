# SPEC: django__django-14539

Status: constructed, not machine-checked. No tests, Python snippets, or K tools
were run.

## Scope

The audited unit is `django.utils.html.urlize()`, specifically its nested
`trim_punctuation()` helper in `repo/django/utils/html.py`. The template filter
in `repo/django/template/defaultfilters.py` is in compatibility scope because it
delegates to this utility, but no template-filter code changed.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| I-001 | prompt | `urlize('Search for google.com/?q=1&lt! and see.')` expected `google.com/?q=1&lt</a>!` | For escaped URL text followed by trailing punctuation, the escaped URL text remains inside the link and the punctuation moves outside exactly once. | Encoded in O-001/O-003. |
| I-002 | prompt | Actual output duplicated `lt!` after the link. | The source split must not duplicate characters when unescaped text is shorter than source text. | Encoded in O-002. |
| I-003 | docstring | `Links can have trailing punctuation ... and it'll still do the right thing.` | Trailing characters in `TRAILING_PUNCTUATION_CHARS` are outside the link. | Encoded in O-001/O-005. |
| I-004 | code comment | `Unescape entities to avoid breaking them by removing ';'.` | Entity-aware trimming must not corrupt valid entity source spans. | Encoded in O-004/O-005. |
| I-005 | public tests | Escaped query text such as `?x=&amp;y=&lt;2&gt;` remains link text while the href uses quoted unescaped URL text. | URL text source is preserved for display; href is based on `html.unescape(middle)`. | Frame condition O-006. |
| I-006 | public tests | Inputs with multiple trailing `!`, `.`, `,`, `:`, `;` move those characters outside the link. | Runs of literal trailing punctuation are trimmed as a group. | Encoded in O-005/O-007. |
| I-007 | public tests | A long non-URL-ish input ending with `a` remains unchanged. | Avoid adding an obviously unbounded per-character scan on unchanged/non-trailing cases. | Encoded in O-008. |

## Intent Specification

For any candidate URL word split by `urlize()` into `(lead, middle0, trail0)`:

1. Let `U = html.unescape(middle0)`.
2. Let `P` be the maximal suffix of `U` whose characters are all in
   `TRAILING_PUNCTUATION_CHARS`.
3. Let `S` be `U` without suffix `P`.
4. `trim_punctuation()` must return `(lead', middle', trail')` such that:
   - `html.unescape(middle') == S`.
   - `trail' == source_suffix_for(P) + trail0`, where
     `source_suffix_for(P)` is the exact source span in `middle0` that decodes
     to the trailing punctuation suffix.
   - `middle' + source_suffix_for(P) == middle0` after any independently
     trimmed wrapping punctuation has been accounted for.
   - No source character is duplicated or lost.
   - A source entity that decodes to non-punctuation remains in `middle'`.
   - A source entity that decodes entirely to trailing punctuation moves as a
     whole source entity into the trail.

The rest of `urlize()` is a frame condition for this issue: URL recognition,
email handling, IDN conversion, `smart_urlquote()`, `nofollow`, `trim_url()`, and
autoescape behavior must remain unchanged except for receiving the corrected
`middle` and `trail` split.

## V2 Code Decision

V1 changed the original absolute-index slice to a count-based slice. That fixed
I-001 for literal punctuation after an escaped sequence such as `&lt!`.

The FVK audit found that V1 still did not satisfy I-004 for punctuation encoded
as an entity. Example: for `middle0 == "google.com/&#33;"`, V1 would remove only
the final `;` from source, leaving `middle' == "google.com/&#33"` and
`trail == ";"`. That violates the source-span obligation above by breaking the
entity that represents the visible trailing `!`.

V2 therefore trims:

- a whole trailing entity source span when `html.unescape(span)` is non-empty and
  consists only of trailing punctuation characters;
- otherwise a run of literal trailing punctuation source characters.

## Compatibility Audit

No public signature, return type, import, registry entry, or template filter
signature changed. Existing callers still call `urlize(text, trim_url_limit=None,
nofollow=False, autoescape=False)` and the template filter still delegates via
`_urlize(value, nofollow=True, autoescape=autoescape)`.

## Formal Core

The formal core is in:

- `fvk/mini-urlize.k`
- `fvk/urlize-trim-spec.k`

Those files model only the source-span trimming fragment needed for the issue.
They intentionally abstract away unrelated URL recognition and quoting, which
are frame conditions in this audit.
