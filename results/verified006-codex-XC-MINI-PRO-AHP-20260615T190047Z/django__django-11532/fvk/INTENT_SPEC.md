# Intent Specification

Status: constructed for FVK audit; no code, tests, Python, or K tooling was executed.

## Public intent obligations

1. Default email `Message-ID` generation must not crash when the computer hostname contains non-ASCII characters and the email encoding is a non-Unicode charset such as `iso-8859-1`.

2. The domain used in a default `Message-ID` must be ASCII-compatible. A non-ASCII DNS name such as the issue's `"漢字"` must be converted to IDNA/punycode, yielding `"xn--p8s937b"` for that concrete value.

3. ASCII DNS names must be preserved unchanged.

4. The hostname cache must remain lazy: `socket.getfqdn()` is still called only when the cached DNS name is first needed, and the cached value is reused after that.

5. Explicit user-supplied `Message-ID` headers must continue to override Django's default generated value.

6. The shared mail DNS-name utility may normalize the value used by SMTP `local_hostname`; this is consistent with the issue's requested domain-name punycoding and does not change signatures.

## Domain assumptions

The formalized domain is DNS-name-like values whose `str()` form is accepted by Python's IDNA codec when non-ASCII. Invalid hostnames outside that domain are not specified by the public issue.
