# Proof Obligations

Status: constructed obligations for the V1/V2 audit.

PO-001. Shortcut normalization

- Claim: For parsed non-IPv6 `0:P`, address handling must store the canonical wildcard address `0.0.0.0`.
- Evidence: E-001, E-004.
- K claim: `BUGFIX-ZERO-SHORTCUT`.
- Status: discharged by constructed proof; not machine-checked.

PO-002. Startup URL rendering

- Claim: For parsed non-IPv6 `0:P`, startup output must contain `http://0.0.0.0:P/`, not `http://0:P/`.
- Evidence: E-002, E-003.
- K claim: `BUGFIX-ZERO-SHORTCUT`.
- Status: discharged by constructed proof; not machine-checked.

PO-003. State/display/bind consistency

- Claim: The canonical address used for output is also the address retained in command state and passed toward the server bind.
- Evidence: E-007, E-008.
- K claim: `BUGFIX-ZERO-SHORTCUT`; source audit of `inner_run()` and `run()`.
- Status: discharged by constructed proof plus source inspection; not machine-checked.

PO-004. IPv4 default and port-only frame

- Claim: Omitted and port-only non-IPv6 inputs keep existing defaults.
- Evidence: command docs and public tests.
- K claims: `FRAME-DEFAULT-IPV4`, `FRAME-PORT-ONLY-IPV4`.
- Status: discharged by constructed proof; not machine-checked.

PO-005. IPv6 default and port-only frame

- Claim: Omitted and port-only IPv6 inputs keep existing defaults and raw IPv6 display.
- Evidence: command docs and public tests.
- K claims: `FRAME-DEFAULT-IPV6`, `FRAME-PORT-ONLY-IPV6`.
- Status: discharged by constructed proof; not machine-checked.

PO-006. Explicit IPv4 frame

- Claim: Explicit IPv4 address and port remain unchanged.
- Evidence: command docs and public tests.
- K claim: `FRAME-EXPLICIT-IPV4`.
- Status: discharged by constructed proof; not machine-checked.

PO-007. Hostname/FQDN frame

- Claim: Hostname/FQDN input remains unbracketed and preserves the `use_ipv6` flag.
- Evidence: command docs and public tests.
- K claim: `FRAME-FQDN`.
- Status: discharged by constructed proof; not machine-checked.

PO-008. Bracketed IPv6 frame

- Claim: Bracketed IPv6 literals keep existing behavior.
- Evidence: command docs and public tests.
- K claim: `FRAME-BRACKETED-IPV6`.
- Status: discharged by constructed proof; not machine-checked.

PO-009. Public compatibility

- Claim: No public signature, option, subclass, or delegating command shape changes.
- Evidence: E-009 and `PUBLIC_COMPATIBILITY_AUDIT.md`.
- K claim: not a K reachability claim; compatibility audit obligation.
- Status: satisfied by source inspection.

PO-010. Honesty gate

- Claim: The artifacts must record exact commands and label the proof constructed, not machine-checked; no tests or K tools may be run here.
- Evidence: FVK docs and task constraints.
- K claim: not a K reachability claim; process obligation.
- Status: satisfied by `PROOF.md` and F-005.
