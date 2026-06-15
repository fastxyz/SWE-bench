# Intent Spec

Status: constructed from public intent before accepting V1 behavior as correct.

## Scope

This FVK pass targets the V1 change for `django.utils.html.escape()` and the
small `urlize()` entity helper adjustment made to keep escaped apostrophes
compatible inside the same module. It does not claim whole-Django verification.

## Required Behaviors

I1. `django.utils.html.escape(text)` should use Python stdlib `html.escape()`
for HTML escaping instead of Django's duplicated `_html_escapes` translation
table.

I2. `escape(text)` remains Django's public wrapper: it coerces `text` with
`str()`, always escapes the resulting string even if it is already marked safe,
and returns a value marked safe for HTML output.

I3. The escaped characters are the stdlib `html.escape()` characters with
`quote=True`: `&`, `<`, `>`, `"`, and `'`.

I4. The apostrophe output spelling intentionally changes from Django's previous
`&#39;` to stdlib `&#x27;`. The values are HTML-equivalent, but the literal text is
allowed to change.

I5. `conditional_escape()` remains a non-duplicating wrapper over `escape()`:
objects with `__html__()` are returned through that hook, while other values
use `escape()`.

I6. Public API compatibility is preserved: the public function name,
signature, import path, and safe-string return contract remain unchanged.

I7. `urlize()`'s local URL entity helper should continue to unescape the
entities that `escape()` may produce before feeding URL text to
`smart_urlquote()`. After I4, that includes both the legacy `&#39;` spelling and
the stdlib `&#x27;` spelling for apostrophes.

## Domain Assumptions

D1. Inputs are in domain when Python `str(text)` terminates and returns a
string. Exceptions or side effects from arbitrary user-defined `__str__()`
methods are outside this partial-correctness proof.

D2. Lazy-object behavior is delegated to the unchanged `@keep_lazy(str,
SafeString)` decorator. The proof models the forced/eager call that the
decorator eventually invokes.

D3. The exact algorithm inside stdlib `html.escape()` is a trusted library
dependency for this targeted proof. The proof obligation is that Django calls
that helper with the correct coerced string and preserves wrapper semantics.
