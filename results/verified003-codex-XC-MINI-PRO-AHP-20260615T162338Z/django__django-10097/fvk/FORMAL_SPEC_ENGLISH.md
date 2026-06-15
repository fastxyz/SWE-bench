# Formal Spec English

This file paraphrases the nontrivial K claims in `urlvalidator-spec.k`.

## AUTH-UNCLEAN-REJECTED

For any URL with an allowed scheme, a valid host, and a valid tail, validation
returns `invalid` when the userinfo component is present but its credential
fields are not clean.

## AUTH-FORBIDS-SLASH

The concrete credential field `foo/bar` is unclean, so a URL using it as
userinfo is invalid even when the scheme, host, and tail are otherwise valid.

## AUTH-FORBIDS-RAW-AT

The concrete credential field `foo@bar` is unclean, so a URL using it as
userinfo is invalid even when the scheme, host, and tail are otherwise valid.

## AUTH-FORBIDS-EXTRA-COLON

The concrete password field `pa:ss` is unclean, so a URL using
`user:pa:ss@host` shape is invalid even when the scheme, host, and tail are
otherwise valid.

## QUERY-OR-PATH-SMUGGLING-REJECTED

When a path/query delimiter prevents a pre-host substring from being userinfo,
an invalid host remains invalid. This captures the issue's
`http://foo/bar@example.com` example and the `?m=foo@example.com` smuggling
family at the component level.

## CLEAN-USERINFO-PRESERVED

An ordinary clean `userid:password@host` URL remains valid when the scheme,
host, and tail are valid.

## PERCENT-ENCODED-DELIMITERS-PRESERVED

Credential fields containing percent-encoded delimiters, represented by
`foo%40` and `bar%2f`, remain valid because they do not contain raw forbidden
delimiters.
