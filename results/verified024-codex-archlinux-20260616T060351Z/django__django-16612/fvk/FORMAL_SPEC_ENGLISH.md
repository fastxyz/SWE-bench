# FORMAL SPEC ENGLISH

Status: paraphrase of the K-style claims in `fvk/admin-catch-all-spec.k`.

## CATCH-REDIRECT-PRESERVES-QUERY

For any symbolic path and query string, if `APPEND_SLASH` is true, the captured
admin URL does not already end in `/`, the slash-appended route resolves, and
the resolved view permits slash appending, the catch-all transition returns a
redirect whose location is `fullPathSlash(PATH, QUERY)`.

## FULL-PATH-NONEMPTY-QUERY

For any symbolic path and any non-empty query string, `fullPathSlash(PATH,
QUERY)` is the slash-adjusted path followed by `?` and the encoded query
string.

## FULL-PATH-EMPTY-QUERY

For any symbolic path and an empty query string, `fullPathSlash(PATH, "")` is
only the slash-adjusted path and does not include a trailing `?`.

## CATCH-NO-REDIRECT-WHEN-GATES-FAIL

If `APPEND_SLASH` is false, or the captured URL already ends in `/`, or the
slash-appended route does not resolve, or the resolved view opts out of slash
appending, the catch-all transition reaches `Http404`.

## Frame and Compatibility Conditions

The formal claims do not change the method signature, URL registration, or
meaning of the `should_append_slash` gate. They constrain only the redirect
location in the already-existing redirect branch.
