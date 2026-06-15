# Constructed Proof

Status: constructed, not machine-checked. No Python, Django tests, `kompile`,
or `kprove` were run.

## Claims Proved by Construction

The K-style claims are in `html-escape-spec.k` and use the minimal semantics in
`mini-python.k`.

1. For any in-domain eager object represented as `Obj(S)`,
   `escape(Obj(S))` rewrites to `SafeString(HtmlEscape(S))`.
2. For any already-safe input represented as `SafeString(S)`,
   `escape(SafeString(S))` still rewrites to `SafeString(HtmlEscape(S))`.
3. For the apostrophe input, `escape(Obj("'"))` rewrites to
   `SafeString("&#x27;")`.
4. Representative core characters rewrite to the stdlib escaped strings.
5. `url_unescape("...&#x27;")` and `url_unescape("...&#39;")` both rewrite to
   strings containing an apostrophe before URL quoting.

`HtmlEscape(S)` is the spec abstraction for stdlib
`html.escape(S, quote=True)`.

## Symbolic Execution Sketch

For eager input `Obj(S)`:

```text
escape(Obj(S))
=> mark_safe(_html_escape(str(Obj(S))))
=> mark_safe(_html_escape(S))
=> mark_safe(HtmlEscape(S))
=> SafeString(HtmlEscape(S))
```

The same sequence for `SafeString(S)` differs only in the `str()` step:

```text
str(SafeString(S)) => S
```

Therefore the safe marker on input does not suppress escaping, satisfying the
"always escape" docstring obligation.

For apostrophe input, instantiate `S = "'"` and use the stdlib abstraction
axiom:

```text
HtmlEscape("'") = "&#x27;"
```

The result is:

```text
escape(Obj("'")) => SafeString("&#x27;")
```

For the URL helper compatibility claim, instantiate the helper abstraction with
the two public apostrophe entity spellings:

```text
UrlEntityUnescape("...&#39;")  = "...'"
UrlEntityUnescape("...&#x27;") = "...'"
```

V1's source implements the second equality by adding the `&#x27;` replacement
without removing the existing `&#39;` replacement.

## Adequacy Gate

`SPEC_AUDIT.md` maps each formal claim back to `INTENT_SPEC.md`. All formal
claims pass the adequacy check. No claim preserves the legacy `&#39;` spelling as
required behavior; that legacy expectation is marked SUSPECT in `FINDINGS.md`.

`PUBLIC_COMPATIBILITY_AUDIT.md` found no public signature, import-path,
override, or producer/consumer incompatibility.

## Machine-Check Commands

These commands are recorded for a future environment with K installed. They
were not executed in this benchmark session.

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/html-escape-spec.k
kprove fvk/html-escape-spec.k --definition fvk/mini-python-kompiled
```

Expected result after successful machine checking: `#Top` for all claims.

## Test Redundancy Recommendation

No tests should be removed in this benchmark run.

Conditioned on a successful machine check and updated public expectations for
the apostrophe literal, simple unit assertions that check individual in-domain
character mappings of `escape()` would be subsumed by the formal claims. Keep
integration tests, lazy-object tests, `conditional_escape()` tests, `urlize()`
tests, and any tests covering behavior outside this targeted proof.

## Residual Risk

- Partial correctness only: termination and performance are not proved.
- The mini semantics abstracts stdlib `html.escape()` as `HtmlEscape(S)`.
- Lazy proxy behavior from `@keep_lazy` is framed as unchanged, not re-proved.
- The proof is constructed but not machine-checked.
