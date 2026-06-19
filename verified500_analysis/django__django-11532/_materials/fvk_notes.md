# FVK Notes

## Decisions and traceability

### Changed `repo/django/core/mail/utils.py`

I kept the V1 behavior that normalizes the real cached hostname path, because `fvk/FINDINGS.md` records it as `F2` and `fvk/PROOF_OBLIGATIONS.md` records the required cache behavior as `PO3` and `PO4`.

I factored the encoding logic into `punycode(domain)` so both the cache path and the `Message-ID` use site share the same ASCII-preservation and IDNA-conversion obligations. This traces to `PO1` and `PO2`.

### Changed `repo/django/core/mail/message.py`

I revised V1 by changing the default `Message-ID` branch from `make_msgid(domain=DNS_NAME)` to `make_msgid(domain=punycode(DNS_NAME))`.

The reason is `F1`: V1 handled `socket.getfqdn()` returning Unicode, but it did not handle the issue's executable-snippet interpretation where `DNS_NAME` itself is a Unicode value at the `message.py` use site. `PO5` requires the domain passed to `make_msgid()` to be normalized before header assignment can encounter it as raw Unicode.

### Kept explicit `Message-ID` override behavior unchanged

The code still skips default message-id generation when `extra_headers` contains a case-insensitive `message-id` key. This traces to `PO6` and the compatibility frame in `PO7`.

### Did not add invalid-hostname handling

`F3` records invalid IDNA hostnames as outside the public issue's specified domain. I did not add fallback behavior or a Django-specific exception because no public evidence specifies the desired policy for values Python's IDNA codec rejects.

## Verification status

The FVK proof is constructed, not machine-checked, as recorded in `F4` and `fvk/PROOF.md`. I did not run Python tests, Django code, `kompile`, `kast`, or `kprove`, per the task constraints.
