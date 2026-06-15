# FVK Spec

Status: constructed, not machine-checked. This is a targeted verification
artifact for the V1 fix to `django.utils.html.escape()`, not a proof of all of
Django.

## Public Intent Ledger

The full ledger is in `PUBLIC_EVIDENCE_LEDGER.md`. The controlling entries are:

- E1/E2: the issue explicitly asks to use stdlib `html.escape()` and identifies
  Django's `_html_escapes` table as duplication.
- E5: the issue explicitly accepts the apostrophe literal change from `&#39;` to
  stdlib `&#x27;`.
- E6/E7: the `escape()` docstring requires escaping ampersands, quotes, and
  angle brackets, and requires escaping even already-safe input.
- E8/E9: safe-string and `conditional_escape()` contracts require safe output
  and no duplicate escaping for objects that provide `__html__()`.
- E10: `urlize()`'s helper must unescape HTML-escaped URL text before URL
  quoting.

## Formal Domain

For the primary function contract, `text` is in domain when:

- Python `str(text)` terminates and returns string `S`.
- stdlib `html.escape(S, quote=True)` terminates.
- The proof is partial correctness: if the call returns, the returned value
  satisfies the postcondition.

The unchanged lazy wrapper `@keep_lazy(str, SafeString)` is treated as a frame
condition. The formal core models the eager function body invoked by that
decorator.

## Functional Contract

For every in-domain input with `str(text) = S`:

```text
escape(text) == mark_safe(html.escape(S, quote=True))
```

The returned object's string content is `html.escape(S, quote=True)` and its
safe marker is preserved by `mark_safe()`.

For already-safe input with string content `S`, the same contract applies:

```text
escape(mark_safe(S)) == mark_safe(html.escape(S, quote=True))
```

This preserves "always escape" and allows double escaping of already-escaped
content.

## Character Obligations

The escaped output for the five named core characters follows stdlib
`html.escape(quote=True)`:

| Input character | Required output |
| --- | --- |
| `&` | `&amp;` |
| `<` | `&lt;` |
| `>` | `&gt;` |
| `"` | `&quot;` |
| `'` | `&#x27;` |

The previous Django apostrophe spelling `&#39;` is not a preservation obligation
because E5 identifies the spelling change as expected public intent.

## URL Entity Helper Contract

Inside `urlize()`, escaped URL text is unescaped before `smart_urlquote()`.
Because `escape()` can now produce `&#x27;`, the local helper must accept:

```text
&#39;  -> '
&#x27; -> '
```

alongside its existing `&amp;`, `&lt;`, `&gt;`, and `&quot;` mappings.

## K Artifacts

- `mini-python.k`: mini semantics for the wrapper, safe-string marker, stdlib
  escape abstraction, and URL entity helper.
- `html-escape-spec.k`: K-style reachability claims with provenance comments.

The claims use `HtmlEscape(S)` as an abstraction for stdlib
`html.escape(S, quote=True)`. Verifying the stdlib implementation itself is
outside this targeted proof.
