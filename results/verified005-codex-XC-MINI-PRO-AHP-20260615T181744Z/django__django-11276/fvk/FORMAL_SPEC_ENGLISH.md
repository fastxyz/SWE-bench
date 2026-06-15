# Formal Spec in English

Status: paraphrase of `html-escape-spec.k`, constructed and not
machine-checked.

K1. ESCAPE-OBJECT: For every in-domain object represented by `Obj(S)`,
executing `escape(Obj(S))` reaches `SafeString(HtmlEscape(S))`.

K2. ESCAPE-SAFE-INPUT: For every in-domain safe string represented by
`SafeString(S)`, executing `escape(SafeString(S))` reaches
`SafeString(HtmlEscape(S))`; the safe marker on input does not bypass escaping.

K3. APOSTROPHE-USES-STDLIB-SPELLING: Executing `escape(Obj("'"))` reaches
`SafeString("&#x27;")`, matching stdlib `html.escape()`'s apostrophe spelling.

K4. CORE-CHARACTERS: For representative one-character inputs, escaping maps
`&` to `&amp;`, `<` to `&lt;`, `>` to `&gt;`, `"` to `&quot;`, and `'` to
`&#x27;`.

K5. URLIZE-X27-COMPATIBILITY: The `urlize()` local entity helper maps the
stdlib apostrophe entity `&#x27;` back to an apostrophe before URL quoting, just
as it already does for Django's previous `&#39;` spelling.

K6. Frame condition: the public callable shape remains `escape(text)` and the
result remains a safe-string object containing the escaped text.

K7. Trusted abstraction: `HtmlEscape(S)` denotes stdlib `html.escape(S,
quote=True)`. The constructed proof checks that Django delegates to it and
wraps the result, not the internals of the stdlib implementation.
