# Public Evidence Ledger

## E1

- Source: prompt / issue description
- Evidence: "Email messages crash on non-ASCII domain when email encoding is non-unicode."
- Semantic obligation: Default email message construction must avoid Unicode-domain header crashes under non-Unicode encodings.
- Status: encoded in `MESSAGE-ID-DEFAULT` and proof obligation `PO5`.

## E2

- Source: prompt / issue reproduction
- Evidence: "Set hostname to non iso-8859-1 value (i.e. hostname 正宗)"
- Semantic obligation: The system hostname returned through Django's cached DNS-name path is in scope.
- Status: encoded in `CACHED-DNS-MISS` and proof obligation `PO3`.

## E3

- Source: prompt / proposed fix
- Evidence: "convert domain name to punycode before using"
- Semantic obligation: Non-ASCII domains must be converted with IDNA/punycode before they are included in `Message-ID`.
- Status: encoded in `PUNYCODE-NONASCII`, `MESSAGE-ID-DEFAULT`, `PO2`, and `PO5`.

## E4

- Source: prompt / executable snippet
- Evidence: `with patch("django.core.mailmessage.DNS_NAME", "漢字") ... self.assertIn('xn--p8s937b', message['Message-ID'])`
- Semantic obligation: A Unicode `DNS_NAME` value at the `message.py` use site must be normalized before `make_msgid()` builds the header.
- Status: V1 finding `F1`; resolved by V2's `punycode(DNS_NAME)` call in `EmailMessage.message()`.

## E5

- Source: traceback
- Evidence: `Header(val, encoding).encode()` raises `UnicodeEncodeError` for the generated `Message-ID`.
- Semantic obligation: The generated `Message-ID` header value must be ASCII before header encoding sees it.
- Status: encoded in `MESSAGE-ID-DEFAULT` and `PO5`.

## E6

- Source: source comment in `django/core/mail/utils.py`
- Evidence: "Cache the hostname, but do it lazily: socket.getfqdn() can take a couple of seconds"
- Semantic obligation: Preserve lazy cache behavior.
- Status: encoded in `CACHED-DNS-MISS`, `CACHED-DNS-HIT`, `PO3`, and `PO4`.

## E7

- Source: public tests in `tests/mail/tests.py`
- Evidence: "Specifying dates or message-ids in the extra headers overrides the default values (#9233)"
- Semantic obligation: Do not replace or normalize an explicit `Message-ID` supplied in `extra_headers`.
- Status: encoded in `MESSAGE-ID-OVERRIDE` and `PO6`.

## E8

- Source: existing implementation in `sanitize_address()`
- Evidence: non-ASCII email address domains are converted with `domain.encode('idna').decode('ascii')`.
- Semantic obligation: IDNA is Django's existing local convention for mail-domain normalization.
- Status: supports `PUNYCODE-NONASCII`; not used as a sole source of intent.
