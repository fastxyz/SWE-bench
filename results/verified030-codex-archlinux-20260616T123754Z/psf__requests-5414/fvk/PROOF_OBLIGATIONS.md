# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Concrete Reported URL

Input: host `.example.com`, representing `http://.example.com` after successful
URL parsing.

Obligation: `prepareAsciiHost(".example.com")` reaches
`invalidURL("URL has an invalid label.")`.

Evidence: E-1 and E-2 in `fvk/SPEC.md`.

Status: discharged by the V2 source guard `host.startswith(u'.')`.

## PO-2: Leading Empty ASCII Label Family

Input class: any ASCII host `H` where `StartsWith(H, ".")`.

Obligation: the host validation branch raises Requests `InvalidURL` with
`URL has an invalid label.`

Evidence: E-1, E-2, and E-3 in `fvk/SPEC.md`.

Status: discharged by the V2 source guard `host.startswith(u'.')`.

## PO-3: Interior Empty ASCII Label Family

Input class: any ASCII host `H` where `Contains(H, "..")`.

Obligation: the host validation branch raises Requests `InvalidURL` with
`URL has an invalid label.`

Evidence: E-2 and E-3 in `fvk/SPEC.md`.

Status: discharged by the V1/V2 source guard `u'..' in host`.

## PO-4: Existing Wildcard Rejection Is Preserved

Input class: any ASCII host `H` where `StartsWith(H, "*")`.

Obligation: the host validation branch continues to raise Requests `InvalidURL`
with `URL has an invalid label.`

Evidence: E-5 in `fvk/SPEC.md`.

Status: discharged because the V2 condition retains `host.startswith(u'*')`.

## PO-5: Non-ASCII IDNA Handling Is Preserved

Input class: any host for which `unicode_is_ascii(host)` is false.

Obligation: the existing `_get_idna_encoded_host` path remains unchanged:
successful IDNA encoding updates `host`; IDNA failure is converted to
`InvalidURL('URL has an invalid label.')`.

Evidence: E-4 in `fvk/SPEC.md`.

Status: discharged by source diff inspection; V2 edits only the ASCII `elif`
comment and predicate, not the non-ASCII branch.

## PO-6: Valid ASCII Hosts Are Not Newly Rejected

Input class: ASCII hosts that do not start with `*` or `.` and do not contain
`..`.

Obligation: the new guard does not reject these hosts on the ASCII validation
branch. URL reconstruction and later behavior remain governed by the existing
Requests code.

Evidence: E-5 in `fvk/SPEC.md`.

Status: discharged by the negation of `BadAsciiHost(H)` in the reduced K model
and by inspection of the source predicate.

## PO-7: Trailing Dot Is Not Reclassified By This Fix

Input class: ASCII hosts such as `example.com.` that have a single trailing dot
but no leading dot, no wildcard prefix, and no doubled dot.

Obligation: V2 should not reject this class as part of the empty-label fix,
because the public issue does not prohibit fully qualified domain-name syntax
and the existing branch intentionally avoids full ASCII IDNA validation.

Evidence: E-5 in `fvk/SPEC.md`; absence of contrary public intent in
`benchmark/PROBLEM.md`.

Status: discharged because `example.com.` does not satisfy
`host.startswith(u'.')`, `host.startswith(u'*')`, or `u'..' in host`.

## PO-8: No Public API Compatibility Regression

Input class: callers of `Request.prepare`, `PreparedRequest.prepare_url`, and
high-level APIs such as `requests.get`.

Obligation: method signatures, return shapes, imports, and exception hierarchy
remain compatible.

Evidence: compatibility audit in `fvk/SPEC.md`.

Status: discharged by source diff inspection; only an internal validation branch
and adjacent comment changed.

## PO-9: Honesty Gate

Obligation: proof artifacts must record exact K commands but must not claim the
proof was machine-checked.

Evidence: FVK `verify.md` honesty gate.

Status: discharged in `fvk/SPEC.md` and `fvk/PROOF.md`; commands are recorded
but not executed.
