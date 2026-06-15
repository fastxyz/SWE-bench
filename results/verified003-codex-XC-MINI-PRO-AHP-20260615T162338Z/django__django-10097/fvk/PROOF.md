# PROOF

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## Claims Proved in the Mini Model

The constructed K artifacts are:

- `fvk/mini-urlvalidator.k`
- `fvk/urlvalidator-spec.k`

The proof covers the userinfo delimiter property of `URLValidator`, not the full
Python regex engine.

## Proof Sketch

### AUTH-UNCLEAN-REJECTED

Initial state:

```k
<k> validate(url("http", A, true, true)) </k>
requires notBool authFieldsClean(A)
```

`hasAllowedScheme("http")` rewrites to `true`. The invalid-auth rule in
`mini-urlvalidator.k` applies because `notBool authFieldsClean(A)` holds. The
state reaches:

```k
<k> invalid </k>
```

This discharges PO1.

### AUTH-FORBIDS-SLASH

For `user("foo/bar")`, `cleanField("foo/bar")` rewrites to `false`, so
`authFieldsClean(user("foo/bar"))` rewrites to `false`. The proof then follows
`AUTH-UNCLEAN-REJECTED` and reaches `invalid`.

This discharges PO2.

### AUTH-FORBIDS-RAW-AT

For `user("foo@bar")`, `cleanField("foo@bar")` rewrites to `false`, so the
invalid-auth rule applies and reaches `invalid`.

This discharges the raw-at part of PO3.

### AUTH-FORBIDS-EXTRA-COLON

For `userPass("user", "pa:ss")`, `cleanField("pa:ss")` rewrites to `false`, so
`authFieldsClean(userPass("user", "pa:ss"))` rewrites to `false`. The
invalid-auth rule reaches `invalid`.

This discharges the extra-colon part of PO3.

### QUERY-OR-PATH-SMUGGLING-REJECTED

The component model represents V1's delimiter behavior by classifying a
pre-host path/query/fragment delimiter as `noAuth` plus an invalid host, rather
than as userinfo. In:

```k
<k> validate(url("http", noAuth, false, true)) </k>
```

`hasAllowedScheme("http")` and `authFieldsClean(noAuth)` rewrite to `true`, but
`hostAndTailValid(false, true)` rewrites to `false`. The invalid-host/tail rule
reaches `invalid`.

This discharges PO4 and the path/query aspect of PO2.

### CLEAN-USERINFO-PRESERVED

For `userPass("userid", "password")`, both `cleanField` facts rewrite to
`true`, so `authFieldsClean(...)` is `true`. With `hostAndTailValid(true, true)`
also `true`, the valid rule reaches `valid`.

This discharges PO5.

### PERCENT-ENCODED-DELIMITERS-PRESERVED

For `userPass("foo%40", "bar%2f")`, both concrete fields rewrite to `true`.
With valid scheme, host, and tail, the valid rule reaches `valid`.

This discharges PO6.

## Source-Level Composition

The source patch implements the same classification:

```python
userinfo_re = r'[^\s:/@?#]+(?::[^\s:/@?#]*)?'
```

The first character class requires at least one username character and excludes
raw `:`, `/`, `@`, `?`, and `#`. The optional second part allows one separator
colon and then a password field that excludes the same raw characters. The final
literal `@` in the surrounding regex terminates userinfo.

For slash, query, and fragment smuggling cases, the auth branch cannot consume
the delimiter, so parsing falls through to the host/path/query/fragment
structure. If the pre-delimiter host is invalid, the URL remains invalid. For
extra raw `@` or extra raw `:`, the auth branch fails and no later branch turns
those characters into valid host syntax.

The IDNA fallback reruns the same regex after encoding the netloc. It does not
remove or encode the raw forbidden delimiters, so it does not reintroduce the
bug. This discharges PO7 by inspection.

## Test Redundancy Recommendation

No tests were deleted or edited.

Conditioned on future machine-checking, simple in-domain tests for ordinary
credential preservation and the concrete forbidden delimiter examples are
subsumed by the constructed claims. Keep integration tests, host grammar tests,
IDNA tests, IPv6 tests, max-length tests, and any test that exercises behavior
outside this userinfo delimiter model.

The visible fixture with raw extra colons should not be treated as a reason to
weaken the fix; it is SUSPECT legacy evidence under Finding F3.

## Reproduce the Machine Check Later

These commands were intentionally not run in this session:

```sh
kompile fvk/mini-urlvalidator.k --backend haskell
kast --backend haskell fvk/urlvalidator-spec.k
kprove fvk/urlvalidator-spec.k
```

Expected machine-check result after any K syntax corrections required by the
local toolchain: `#Top` for the claims in `urlvalidator-spec.k`.

## Residual Risk

The proof is constructed, not machine-checked. It proves a component-level model
of the changed userinfo delimiter behavior, not the full Python implementation
of `re`, `urlsplit()`, IDNA, host grammar, or IPv6 validation.
