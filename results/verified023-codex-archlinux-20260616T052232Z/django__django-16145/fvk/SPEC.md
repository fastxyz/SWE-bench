# FVK Spec

Status: constructed, not machine-checked.

## Scope

Target: `django.core.management.commands.runserver.Command.handle()` and the startup URL construction in `Command.inner_run()`.

The proof model abstracts away Django startup work that is not relevant to the issue: settings validation, autoreload, system checks, migration checks, handler construction, socket errors, and `serve_forever()`. The modeled observable is the parsed address state plus the startup line:

`Starting development server at http://<addr>:<port>/`

## Public Intent Ledger Summary

- E-001 and E-004 require non-IPv6 `0:port` to mean `0.0.0.0:port`.
- E-002 and E-003 require the startup URL to render `0.0.0.0`, not `0`.
- E-007 and E-008 make a display-only fix insufficient because `self.addr` is observable in public tests and feeds both display and bind.
- E-005 and E-006 constrain IPv6: `::` is the documented IPv6 wildcard, and `--ipv6` defaults to `::1`.
- E-009 requires no signature or delegation shape changes.

## Specifications

S-001. For valid parsed input `addrport = "0:P"` and `use_ipv6 = False`, after address handling:

- `addr == "0.0.0.0"`
- `port == P`
- `use_ipv6 == False`
- `_raw_ipv6 == False`

S-002. For the same input, the startup line uses:

`Starting development server at http://0.0.0.0:P/`

S-003. The server bind path receives the same canonical `addr` value used by the startup line.

S-004. For omitted `addrport` with `use_ipv6 = False`, the default address remains `127.0.0.1` and the default port remains `8000`.

S-005. For port-only input `P` with `use_ipv6 = False`, the address remains `127.0.0.1` and the port becomes `P`.

S-006. For port-only input `P` with `use_ipv6 = True`, the address remains `::1`, the port becomes `P`, `_raw_ipv6 = True`, and display uses `[::1]`.

S-007. For explicit IPv4 `A:P` with `use_ipv6 = False`, the address remains `A` and the port remains `P`.

S-008. For hostname/FQDN `H:P`, the address remains `H`; with `--ipv6`, the command may use IPv6 while still displaying the hostname without brackets.

S-009. For bracketed IPv6 `[A]:P`, the command stores `A`, sets `use_ipv6 = True`, sets `_raw_ipv6 = True`, and displays `[A]`.

S-010. For omitted `addrport` with `use_ipv6 = True`, the default address remains `::1`, `_raw_ipv6 = True`, and display uses `[::1]`.

S-011. `--ipv6 0:P` remains outside the positive shortcut obligation. Existing behavior treats `0` as a hostname-like value because public docs name `::` as the IPv6 wildcard and do not document `0` as an IPv6 shortcut.

## Formal Artifacts

- `fvk/mini-runserver.k` gives a reduced K semantics for parsed `addrport` handling and startup URL rendering.
- `fvk/runserver-spec.k` gives reachability claims for S-001 through S-010 and frame behavior.
- There are no loops in the modeled unit, so there are no loop circularity claims.
