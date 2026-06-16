# FVK Notes

## Decisions

Kept the V1 quoted-header change because F-1 and PO-1 trace directly to the public issue's qop quoting requirement. The header fragment remains `qop="auth"`.

Changed V1 further because F-2 and PO-2 show V1 was incomplete for quoted multi-token qop-options. In V1, the header selected `auth`, but the digest input could still use the raw options string. The V2 source edit constructs `noncebit` only after confirming `auth` is present and uses the selected token `'auth'`.

Added whitespace-tolerant qop option membership with `[x.strip() for x in qop.split(',')]` because F-2's input class is a token list, and PO-2 is about selected-token consistency for the list, not byte-for-byte reuse of the challenge string.

Left the no-qop branch unchanged because PO-3 requires preserving the existing no-qop digest path and no finding indicated a qop formatting problem when qop is absent.

Left `auth-int` unsupported because F-3 and PO-4 classify it as an explicit residual boundary, not as proof success. Implementing `auth-int` would require a new entity-body hash contract outside this issue's qop quoting repair.

Made no public API changes because PO-5 and F-4 require preserving `HTTPDigestAuth` construction, `build_digest_header(self, method, url)`, and internal callsites.

## Files Changed

`repo/requests/auth.py`: retained V1's quoted qop header and added selected-token consistency for the response digest input.

`fvk/*`: added the requested FVK artifacts plus the method-required intent, adequacy, compatibility, and `.k` files.

`reports/fvk_notes.md`: added this decision trace.

## Verification Status

No tests, Python, `kompile`, `kast`, or `kprove` were run. The proof is constructed only; machine-checking commands are recorded in `fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, and `fvk/ITERATION_GUIDANCE.md`.

