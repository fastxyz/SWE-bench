# PROOF

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Formal core

K artifacts:

- `fvk/mini-urlvalidator.k`
- `fvk/urlvalidator-spec.k`

Exact commands to machine-check later, not executed in this session:

```sh
kompile fvk/mini-urlvalidator.k --backend haskell
kast --backend haskell fvk/urlvalidator-spec.k
kprove fvk/urlvalidator-spec.k
```

Expected machine-check result after a valid K setup: all claims discharge to `#Top`.

## Model

The mini semantics models only the branch structure relevant to `URLValidator.__call__()`:

- `OK` means the validator returns normally.
- `VE` means the validator raises `ValidationError`.
- `hasUnsafe(V)` is true exactly when the value contains tab, carriage return, or line feed.
- `directRegexOK`, `splitOK`, `punycodeOK`, `fallbackRegexOK`, `ipv6Bad`, and `hostTooLong` abstract the existing URL machinery.

This abstraction is intentional. The issue is not whether Django's full URL regex is correct; it is whether unsafe characters can be stripped by `urlsplit()` before the fallback accepts a sanitized value.

## Proof sketch by claim

C-NONSTR. If `isStr(V)` is false, the first source branch raises `ValidationError`. The K rule for `validate(V)` under `not isStr(V)` rewrites directly to `VE`.

C-UNSAFE. If `isStr(V)` and `hasUnsafe(V)`, V1 raises `ValidationError` before computing the scheme or entering the regex/fallback path. The K rule under `hasUnsafe(V)` rewrites directly to `VE` and mentions no split or fallback predicate. This discharges PO-001 through PO-004.

C-BAD-SCHEME. If the value is a string, has no unsafe character, and `schemeAllowed(V)` is false, the scheme branch raises `ValidationError`. This preserves the pre-existing invalid-scheme behavior.

C-DIRECT-ACCEPT. If the value has no unsafe character, the scheme is allowed, the direct regex accepts, IPv6 is valid if present, and hostname length is within the documented limit, validation reaches the normal-return path. The V1 guard is false and therefore frames the old behavior.

C-FALLBACK-ACCEPT. If the value has no unsafe character, the scheme is allowed, the direct regex fails, `urlsplit()` succeeds, punycode succeeds, and the reconstructed URL passes regex and hostname checks, validation reaches the existing IDN normal-return path. The V1 guard is false and therefore does not change IDN support.

C-REGEX-REJECT. If the direct regex fails and any required fallback step fails, validation raises `ValidationError`. The proof is by case split over `splitOK(V)`, `punycodeOK(V)`, and `fallbackRegexOK(V)`.

C-HOST-REJECT. If the regex or fallback path would otherwise accept but IPv6 validation fails or the hostname is too long, the existing post-regex checks raise `ValidationError`.

C-NO-UNSAFE-FRAME. The only V1 condition added before the old code is `hasUnsafe(V)`. Under `not hasUnsafe(V)`, the next observed branch is the same scheme check that existed before V1, and every later URL predicate is reached under the same conditions as before.

## Reported examples

`http://www.djangoproject.com/\n` contains LF, so it satisfies `hasUnsafe(V)`. By C-UNSAFE, the validator returns `VE`.

`http://[::ffff:192.9.5.5]\n` contains LF, so it satisfies `hasUnsafe(V)`. By C-UNSAFE, the validator returns `VE` before any IPv6-specific handling is needed.

## Adequacy and compatibility

The English meaning of the K claims matches the intent obligations in `fvk/SPEC.md`: unsafe LF, CR, and tab inputs reject early; values without those characters continue through the existing URL validation pipeline.

The compatibility audit passes because V1 changes no constructor signature, validator call shape, exception class, success return behavior, or default form/model validator callsite.

## Test guidance

Conditioned on successful machine checking, the two public URLValidator newline tests are subsumed by C-UNSAFE. They should still be kept in this benchmark because the task forbids test edits and because the proof was not machine-checked here.

Keep broader tests for URL syntax, IDN handling, IPv6 validity, hostname length, form/model integration, and regex performance. The K model abstracts those components and does not prove their full correctness.

## Residual risk

The proof is constructed, not machine-checked. It also proves branch-order correctness for the unsafe-character bug, not complete Python URL parsing semantics. If future public evidence shows Python strips additional characters before splitting, the unsafe-character family should be revisited.
