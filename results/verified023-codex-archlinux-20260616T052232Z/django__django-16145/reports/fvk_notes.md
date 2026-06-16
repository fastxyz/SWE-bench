# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not justify an additional source edit.

## Trace to Findings and Proof Obligations

The original issue is captured by F-001. PO-001 and PO-002 require `addrport="0:8000"` without `--ipv6` to canonicalize and display as `0.0.0.0`; PO-003 requires the stored state and displayed address to agree. V1 satisfies these obligations by normalizing `self.addr` to `"0.0.0.0"` before `inner_run()` formats the startup message and before `run()` receives the bind address.

I kept the V1 choice to normalize command state rather than only the output string because F-002 shows the display-only alternative would leave `Command.addr` inconsistent with the documented shortcut. That matters because E-007 shows public tests inspect `Command.addr`, and E-008 shows that same state is passed to the server bind.

I kept the `not self.use_ipv6` guard because F-003 records `--ipv6 0:port` as underspecified. PO-005, PO-007, and PO-008 preserve IPv6 default, hostname, and bracketed-literal behavior already supported by docs and public tests, while E-005 names `::` rather than `0` as the IPv6 wildcard.

No source signatures, option names, subclass hooks, or delegation shapes changed. PO-009 and `PUBLIC_COMPATIBILITY_AUDIT.md` cover the staticfiles subclass and `testserver` delegation.

F-004 and F-005 are process boundaries, not source-change requests. The proof abstracts the regex parser and long-running server lifecycle, and no tests or K tools were run because the task forbids execution. The exact later verification commands are recorded in `fvk/PROOF.md`.
