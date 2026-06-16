# Iteration Guidance

Status: V2 decision package.

## V2 Decision

Keep V1 unchanged.

The audit found that V1 satisfies the positive shortcut obligations:

- F-001 is closed by PO-001, PO-002, and PO-003.
- F-002 rejects the display-only alternative and supports V1's stored-address normalization.
- PO-004 through PO-008 frame the existing documented address forms, and V1 only changes the non-IPv6 `0:port` path.
- PO-009 found no public signature or dispatch compatibility issue.

## Future Tests to Add

Do not edit tests in this task, but a conventional follow-up should add coverage equivalent to:

- `call_command(self.cmd, addrport="0:8000")` stores `addr == "0.0.0.0"`, `port == "8000"`, `use_ipv6 == False`, and `_raw_ipv6 == False`.
- A startup-output test, with server execution mocked, asserts the line contains `http://0.0.0.0:8000/`.
- Existing tests for default IPv4, port-only, hostname, IPv6 default, and bracketed IPv6 should remain.

## Open Clarification

If product owners want to define `runserver --ipv6 0:8000`, ask:

Should `0` under `--ipv6` be treated as an invalid IPv4 shortcut, preserved as a hostname-like value, or mapped to the IPv6 wildcard `::`?

The current public evidence does not answer that; V1 preserves existing behavior.

## Commands for Later Verification

These commands were not run here:

```sh
kompile fvk/mini-runserver.k --backend haskell
kast --backend haskell fvk/runserver-spec.k
kprove fvk/runserver-spec.k
```
