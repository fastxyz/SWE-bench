# Spec Adequacy Audit

Status: constructed, not machine-checked.

| Formal claim | Intent coverage | Verdict |
| --- | --- | --- |
| `PUNYCODE-ASCII` | E3 requires conversion before use, not mutation of already ASCII domains; E8 shows IDNA is only needed for non-ASCII domains. | PASS |
| `PUNYCODE-NONASCII` | E3/E4 require punycoding and specifically expect `"xn--p8s937b"` for `"漢字"`. | PASS |
| `CACHED-DNS-MISS` | E2 puts the system hostname path in scope; E6 requires lazy cache behavior. | PASS |
| `CACHED-DNS-HIT` | E6 requires reuse of the cached hostname after the slow lookup. | PASS |
| `MESSAGE-ID-DEFAULT` | E1/E4/E5 require default `Message-ID` generation to use an ASCII-compatible domain and avoid the observed encoding crash. | PASS |
| `MESSAGE-ID-OVERRIDE` | E7 requires explicit `Message-ID` headers to override defaults. | PASS |

## V1 Adequacy Gap

V1 satisfied `CACHED-DNS-MISS` for the real `socket.getfqdn()` path, but it did not satisfy the executable-snippet reading of E4 where `DNS_NAME` itself is a Unicode value at the `message.py` call site. That gap is recorded as `F1` in `FINDINGS.md` and is resolved by V2's `make_msgid(domain=punycode(DNS_NAME))`.

## Conclusion

The V2 claims are no weaker than the intent specification and do not preserve the legacy non-ASCII `Message-ID` behavior as a contract.
