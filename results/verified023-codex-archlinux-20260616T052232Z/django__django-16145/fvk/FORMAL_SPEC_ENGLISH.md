# Formal Spec English

Status: paraphrase of `fvk/runserver-spec.k`, constructed but not machine-checked.

`BUGFIX-ZERO-SHORTCUT`

For any parsed port string `P`, running address handling on `addrPort(raw0, port(P))` with `use_ipv6 = False` terminates with canonical address `ipv4wild`, port `P`, `useIPv6 = False`, `_raw_ipv6 = False`, and startup output exactly `Starting development server at http://0.0.0.0:P/`.

`FRAME-DEFAULT-IPV4`

With no `addrport` and `use_ipv6 = False`, handling terminates with address `127.0.0.1`, port `8000`, no raw IPv6 formatting, and startup output `http://127.0.0.1:8000/`.

`FRAME-DEFAULT-IPV6`

With no `addrport` and `use_ipv6 = True`, handling terminates with address `::1`, port `8000`, raw IPv6 formatting enabled, and startup output `http://[::1]:8000/`.

`FRAME-PORT-ONLY-IPV4`

For any parsed port string `P`, port-only input with `use_ipv6 = False` keeps the default IPv4 address `127.0.0.1`, uses port `P`, and outputs `http://127.0.0.1:P/`.

`FRAME-PORT-ONLY-IPV6`

For any parsed port string `P`, port-only input with `use_ipv6 = True` keeps the default IPv6 address `::1`, uses port `P`, enables raw IPv6 formatting, and outputs `http://[::1]:P/`.

`FRAME-EXPLICIT-IPV4`

For any explicit IPv4 address `A` and port `P` with `use_ipv6 = False`, handling preserves address `A`, uses port `P`, and outputs `http://A:P/`.

`FRAME-FQDN`

For any hostname/FQDN `H`, port `P`, and `use_ipv6` flag, handling preserves `H`, uses port `P`, does not bracket the hostname, and outputs `http://H:P/`.

`FRAME-BRACKETED-IPV6`

For any bracketed IPv6 literal `A` and port `P`, handling stores the unbracketed address `A`, forces `use_ipv6 = True`, enables raw IPv6 formatting, and outputs `http://[A]:P/`.
