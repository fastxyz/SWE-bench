# Public Evidence Ledger

## E1

Source: prompt.

Evidence: "Make URLValidator reject invalid characters in the username and
password."

Semantic obligation: userinfo validation must reject invalid raw characters in
the username/password values.

Status: encoded in `SPEC.md`, `urlvalidator-spec.k`, and proof obligations
PO1-PO3.

## E2

Source: prompt.

Evidence: "Within the user and password field, any ':', '@', or '/' must be
encoded".

Semantic obligation: raw `:`, `@`, and `/` are not valid data inside either
credential field. The one username/password separator colon is syntax and is
handled separately.

Status: encoded in PO1 and claims `AUTH-FORBIDS-SLASH`,
`AUTH-FORBIDS-RAW-AT`, and `AUTH-FORBIDS-EXTRA-COLON`.

## E3

Source: prompt.

Evidence: "An example URL that should be invalid is
`http://foo/bar@example.com`."

Semantic obligation: the auth parser must not consume `/bar@` as credentials.

Status: encoded in PO2 and `QUERY-OR-PATH-SMUGGLING-REJECTED`.

## E4

Source: prompt.

Evidence: "many of the test cases in tests/validators/invalid_urls.txt would be
rendered valid under the current implementation by appending a query string of
the form `?m=foo@example.com`".

Semantic obligation: `?` must not be consumable by the auth branch before the
host; otherwise invalid hosts can be hidden inside apparent credentials.

Status: encoded in PO4 and `QUERY-OR-PATH-SMUGGLING-REJECTED`.

## E5

Source: public-test.

Evidence: `tests/validators/valid_urls.txt` includes ordinary
`userid:password@example.com` and `userid@example.com` cases.

Semantic obligation: ordinary userinfo forms must remain valid when the host and
the rest of the URL are otherwise valid.

Status: encoded in PO5 and claims `CLEAN-USERINFO-PRESERVED` and
`PERCENT-ENCODED-DELIMITERS-PRESERVED`.

## E6

Source: public-test, marked SUSPECT.

Evidence: `tests/validators/valid_urls.txt` line 51 includes raw extra colons
inside userinfo: `...%40:80%2f::::::@example.com`.

Semantic obligation: none accepted as authoritative. It conflicts with E2
because the extra raw colons are data inside the password value.

Status: recorded as Finding F3. It must not veto the prompt-derived spec.

## E7

Source: implementation.

Evidence: `URLValidator.regex` is the only production source line changed; public
callers instantiate `validators.URLValidator()` in form and model URL fields.

Semantic obligation: maintain the class API and default validator behavior while
changing only acceptance/rejection of the malformed userinfo family.

Status: encoded in PO7 and `PUBLIC_COMPATIBILITY_AUDIT.md`.
