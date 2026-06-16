# Spec Audit

Status: adequacy gate for the constructed claims.

## Claim-by-Claim Audit

`BUGFIX-ZERO-SHORTCUT`: PASS

The English claim matches I-001 through I-003. It is not candidate-derived: the expected `0.0.0.0` is quoted in the problem and tutorial evidence.

`FRAME-DEFAULT-IPV4`: PASS

This is supported by command reference docs and existing public tests for `call_command(self.cmd)` expecting `127.0.0.1:8000`.

`FRAME-DEFAULT-IPV6`: PASS

This is supported by command reference docs and existing public tests for `use_ipv6=True` expecting `::1`, port `8000`, and raw IPv6 formatting.

`FRAME-PORT-ONLY-IPV4`: PASS

This is supported by public tests expecting `addrport="7000"` to keep `127.0.0.1` and set port `7000`.

`FRAME-PORT-ONLY-IPV6`: PASS

This is supported by public tests expecting `addrport="7000", use_ipv6=True` to keep `::1`, set port `7000`, and use raw IPv6 formatting.

`FRAME-EXPLICIT-IPV4`: PASS

This is supported by command reference examples and public tests for `1.2.3.4:8000`.

`FRAME-FQDN`: PASS

This is supported by command reference docs allowing ASCII hostnames and public tests for hostnames, including `--ipv6 localhost:8000` style behavior.

`FRAME-BRACKETED-IPV6`: PASS

This is supported by command reference docs and public tests for `[2001:0db8:1234:5678::9]:7000`.

## Adequacy Notes

The model proves a reduced, parsed-input contract rather than the full Python regex parser. This is adequate for the reported issue because the parser already accepts `0:8000`; the defect is the post-parse normalization and display path. Full regex equivalence is listed as an escalation boundary in F-004.

The model does not prove total correctness of `runserver`, because the real command intentionally enters `serve_forever()`. The proof target is partial correctness of the address state and startup output before that call.

`--ipv6 0:P` remains ambiguous and is not used to justify V1. The audit keeps it out of `BUGFIX-ZERO-SHORTCUT` because public docs identify `::` as the IPv6 wildcard and do not document `0` as an IPv6 shortcut.
