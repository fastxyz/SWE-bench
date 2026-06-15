## Root cause

`django.utils.html.escape()` maintained a private `_html_escapes` translation table
that duplicated Python's stdlib `html.escape()`. This duplicated implementation
escaped the same core HTML-sensitive characters, but it used `str.translate()`
and emitted `&#39;` for apostrophes instead of the stdlib spelling `&#x27;`.

## Files changed

`repo/django/utils/html.py`

- Imported `html.escape()` from the Python standard library as `_html_escape`.
- Removed Django's duplicate `_html_escapes` table.
- Updated `escape()` to keep Django's wrapper semantics: coerce input with
  `str()`, always escape the value, and return the result through `mark_safe()`
  so callers still receive a safe string.
- Updated `urlize()`'s local `unescape()` helper to also understand `&#x27;`.
  It already understood Django's previous apostrophe entity `&#39;`; accepting the
  stdlib spelling keeps escaped URLs produced by the updated `escape()` usable
  by the same module.

`reports/baseline_notes.md`

- Added this required implementation note.

## Assumptions and alternatives

- I assumed Django's public behavior should remain "always escape, even safe
  input" and "return a marked-safe string"; the change is only the escaping
  implementation and the expected stdlib apostrophe spelling.
- I relied on `html.escape()`'s default `quote=True` behavior because Django's
  previous implementation escaped both single and double quotes.
- I treated the `&#39;` to `&#x27;` change as intentional because the issue calls it
  out as a functionally equivalent backwards-incompatible literal change.
- I considered replacing the translation table with a hand-written chain of
  `.replace()` calls to match the stdlib implementation more closely, but
  rejected it because the task specifically asks to use the stdlib helper rather
  than preserve a local duplicate.
- I did not modify tests or documentation and did not run the test suite or
  project code, per the benchmark instructions.
