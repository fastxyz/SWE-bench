# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Credential field grammar

Statement: the auth branch must accept only `user@` or `user:password@`
shapes where `user` and `password` fields do not contain raw `:`, `@`, `/`,
`?`, or `#`.

Source: intent entries E1, E2, E4; code expression
`[^\s:/@?#]+(?::[^\s:/@?#]*)?`.

Discharge: `urlvalidator-spec.k` claim `AUTH-UNCLEAN-REJECTED` and source-level
inspection of `userinfo_re`.

Status: discharged for the modeled property.

## PO2: Reported slash example

Statement: `http://foo/bar@example.com` must be invalid because `/` cannot be
consumed as userinfo before the host.

Source: intent entry E3.

Discharge: `AUTH-FORBIDS-SLASH` and `QUERY-OR-PATH-SMUGGLING-REJECTED`.

Status: discharged for the modeled property.

## PO3: Raw at-sign and extra colon

Statement: a raw `@` inside a credential field and any raw `:` inside the
password field must be rejected. The first `:` separating user and password is
allowed as syntax.

Source: intent entry E2.

Discharge: `AUTH-FORBIDS-RAW-AT`, `AUTH-FORBIDS-EXTRA-COLON`, and source-level
inspection that `userinfo_re` contains exactly one optional separator colon.

Status: discharged.

## PO4: Query and fragment delimiter smuggling

Statement: invalid URLs must not become valid by appending
`?m=foo@example.com`, and the same delimiter-boundary reasoning applies to
fragments.

Source: intent entry E4 and URL component boundary default-domain convention.

Discharge: `QUERY-OR-PATH-SMUGGLING-REJECTED` and source-level inspection that
`?` and `#` are excluded from `userinfo_re`.

Status: discharged.

## PO5: Preserve ordinary credentials

Statement: `userid@example.com` and `userid:password@example.com` remain valid
when the scheme, host, port, and tail are otherwise valid.

Source: public-test evidence E5.

Discharge: `CLEAN-USERINFO-PRESERVED` and source-level inspection that clean
fields and the single separator colon still match.

Status: discharged.

## PO6: Preserve percent-encoded delimiters

Statement: percent-encoded delimiters in userinfo remain acceptable because the
prompt requires encoding invalid delimiters rather than banning the represented
characters altogether.

Source: intent entries E2, E5.

Discharge: `PERCENT-ENCODED-DELIMITERS-PRESERVED` and source-level inspection
that `%` is not excluded by `userinfo_re`.

Status: discharged.

## PO7: IDNA fallback does not reintroduce the bug

Statement: if the first regex check fails on a malformed userinfo delimiter,
the IDNA fallback path must not make the URL valid.

Source: implementation control flow in `URLValidator.__call__`.

Discharge: manual symbolic path analysis. For slash/query/fragment cases,
`urlsplit()` places the delimiter and later `@example.com` outside the netloc, so
the invalid host remains invalid. For extra raw `@` or extra raw `:` cases, IDNA
encoding does not remove the raw delimiter from the netloc, and the second regex
check applies the same `userinfo_re`.

Status: discharged by code inspection; not represented in the mini-K fragment.

## PO8: Public compatibility

Statement: the fix must not change the `URLValidator` public API, constructor,
error type, or downstream default validator wiring.

Source: public compatibility audit.

Discharge: `PUBLIC_COMPATIBILITY_AUDIT.md`.

Status: discharged.

## PO9: Exact Python regex semantics

Statement: the exact Python `re` engine and backtracking behavior for the whole
URL regex should match the component proof.

Source: FVK completeness requirement.

Discharge: not machine-checked in this environment. The source-level regex
inspection is direct enough for the intended production decision, but exact
`re` semantics remain a proof boundary.

Status: proof boundary, not a code bug.
