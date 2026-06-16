# Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, or `kprove` were run.

## Machine-Check Commands

These are the commands to run later in an environment with K installed:

```sh
kompile fvk/mini-runserver.k --backend haskell
kast --backend haskell fvk/runserver-spec.k
kprove fvk/runserver-spec.k
```

Expected machine-check result after the commands are actually run: `#Top` for all claims.

## Semantics Summary

`mini-runserver.k` models the reduced state needed for this issue:

- `<addr>` stores the parsed/canonical command address.
- `<port>` stores the parsed port.
- `<useIPv6>` stores the active IPv6 flag.
- `<rawIPv6>` stores whether display formatting should bracket the address.
- `<output>` stores the startup URL line.

The `handle(...)` rules model the relevant branches of `Command.handle()`. The `emit` rule models the address part of `Command.inner_run()`'s startup line.

## Constructed Proof

`BUGFIX-ZERO-SHORTCUT`

1. Start with `<k> handle(addrPort(raw0, port(P)), false) </k>`.
2. Apply the non-IPv6 `raw0` handling rule. This is the V1 source line `elif self.addr == "0" and not self.use_ipv6: self.addr = "0.0.0.0"` abstracted as `raw0 => ipv4wild`.
3. The state is now `<addr> ipv4wild </addr>`, `<port> port(P) </port>`, `<useIPv6> false </useIPv6>`, `<rawIPv6> false </rawIPv6>`, with `<k> emit </k>`.
4. Apply `emit`. The display function rule `displayAddr(ipv4wild, false) => "0.0.0.0"` rewrites the output to `Starting development server at http://0.0.0.0:P/`.
5. The final `<k>` cell is `.K`, so the claim reaches the required post-state.

`FRAME-DEFAULT-IPV4`

`handle(missing, false)` applies the missing-addrport rule with `defaultAddr(false) => defaultIPv4`, `port("8000")`, `rawIPv6=false`, then `emit` renders `127.0.0.1`.

`FRAME-DEFAULT-IPV6`

`handle(missing, true)` applies the missing-addrport rule with `defaultAddr(true) => defaultIPv6`, `port("8000")`, `rawIPv6=true`, then `emit` renders `[::1]`.

`FRAME-PORT-ONLY-IPV4`

`handle(portOnly(port(P)), false)` applies the port-only rule, keeps `defaultIPv4`, stores `P`, then `emit` renders `127.0.0.1:P`.

`FRAME-PORT-ONLY-IPV6`

`handle(portOnly(port(P)), true)` applies the port-only rule, keeps `defaultIPv6`, stores `P`, sets raw IPv6 formatting, then `emit` renders `[::1]:P`.

`FRAME-EXPLICIT-IPV4`

`handle(addrPort(ipv4(A), port(P)), false)` applies the explicit IPv4 rule, preserves `A`, stores `P`, then `emit` renders `A:P`.

`FRAME-FQDN`

`handle(addrPort(fqdn(H), port(P)), USE)` applies the FQDN rule, preserves `H`, preserves `USE`, keeps `_raw_ipv6` false, then `emit` renders `H:P` without brackets.

`FRAME-BRACKETED-IPV6`

`handle(addrPort(ipv6(A), port(P)), USE)` applies the bracketed IPv6 rule, stores unbracketed `A`, forces `useIPv6=true`, sets `_raw_ipv6=true`, then `emit` renders `[A]:P`.

## Completeness Against Intent

The constructed claims cover the full intent slice for this issue: every contributor to the bad observable is modeled. The reported bad URL is produced from parsed address state plus `inner_run()` formatting; V1 changes the parsed address state before `inner_run()` consumes it.

The proof deliberately does not cover the whole Django management command lifecycle. F-004 records that boundary and keeps tests/integration checks necessary.

## Test Guidance

No tests were modified. If machine checking later returns `#Top`, narrow unit tests that assert the in-domain address formatting points may be considered redundant with the proof, but removal is recommendation-only. Integration tests, invalid parser tests, socket error tests, autoreload tests, and long-running server behavior remain outside the proof and should be kept.
