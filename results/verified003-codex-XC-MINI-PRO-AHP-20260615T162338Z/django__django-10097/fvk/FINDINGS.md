# Findings

Status: FVK findings for the V1 fix. Findings are based only on public intent,
source, visible public tests as evidence, and constructed proof obligations.

## F1: V1 fixes the broad userinfo matcher

Input family: malformed URLs where a raw delimiter appears before the host, such
as `http://foo/bar@example.com`.

Observed in pre-fix code: `\S+` could consume `foo/bar@` as userinfo, allowing
`example.com` to satisfy the host branch.

Expected: raw `/` inside userinfo data is invalid, so this URL must be rejected.

Resolution: V1 replaces `\S+` with `userinfo_re`, which excludes `/` from both
credential fields. Tied obligations: PO1, PO2.

Classification: code bug fixed by V1.

## F2: V1 correctly excludes `?` and `#` even though the RFC quote names only `:`, `@`, and `/`

Input family: an invalid URL followed by `?m=foo@example.com`, or the analogous
fragment form.

Observed in pre-fix code: `\S+` could consume `?m=foo@` before the host, hiding
an invalid earlier authority.

Expected: `?` and `#` are URL component delimiters, not userinfo data in this
context. They must stop the auth branch from matching.

Resolution: V1 excludes `?` and `#` from `userinfo_re`. Tied obligations: PO1,
PO4.

Classification: code bug fixed by V1.

## F3: Existing visible valid fixture with raw extra colons is SUSPECT legacy evidence

Input: `http://-.~_!$&'()*+,;=:%40:80%2f::::::@example.com`.

Observed under V1 reasoning: after the first username/password separator, the
remaining raw colons are inside the password field and are rejected.

Expected from public issue intent: raw `:` inside the user or password field
must be percent-encoded.

Resolution: do not preserve this fixture as authoritative behavior. The FVK
intent-evidence rules classify it as SUSPECT because it conflicts with the
issue's RFC-derived requirement. Tied obligations: PO3.

Classification: test/spec conflict, not a production code bug in V1.

## F4: Ordinary userinfo remains accepted

Input family: `userid@example.com`, `userid:password@example.com`, and the same
forms with valid hosts, ports, and paths.

Observed under V1 reasoning: clean credential fields match `userinfo_re`; one
separator colon is still permitted.

Expected: visible public tests and existing validator behavior support these as
valid URLs.

Resolution: V1 preserves them. Tied obligations: PO5.

Classification: compatibility preserved.

## F5: Percent-encoded delimiters remain accepted

Input family: userinfo values containing encoded delimiters, such as `%40` or
`%2f`.

Observed under V1 reasoning: `%` is not excluded by `userinfo_re`.

Expected: the prompt says invalid delimiters must be encoded, so encoded
delimiters should continue to be valid data.

Resolution: V1 preserves encoded delimiter forms. Tied obligations: PO6.

Classification: compatibility preserved.

## F6: IDNA fallback does not require an additional source change

Input family: malformed auth delimiter cases that fail the first regex check and
enter the IDNA fallback path.

Observed under code inspection: the fallback encodes `netloc` and reruns the
same regex. It does not rewrite raw `/`, `?`, `#`, `@`, or extra `:` into clean
userinfo data.

Expected: fallback should preserve the rejection of malformed userinfo.

Resolution: no extra source edit is needed. Tied obligations: PO7.

Classification: audited path, no code bug found.

## F7: Exact regex-engine proof remains constructed, not machine-checked

Input family: all strings in the audited URLValidator domain.

Observed in this FVK pass: the proof models the relevant userinfo delimiter
axis, but does not execute K, Python, or the Python `re` engine.

Expected: FVK artifacts must label this honestly and keep test-removal
recommendations conditional.

Resolution: `PROOF.md` and `PROOF_OBLIGATIONS.md` mark the exact regex proof as
a proof boundary. This does not justify a source change because the source-level
delimiter reasoning is direct and complete for the issue intent.

Classification: proof boundary, not a code bug.
