# FVK Notes

## Decision

V1 stands unchanged after the FVK audit. The constructed specification and
proof obligations cover the reported zero-worker failure, the analogous
quota/period fractional case, and the propagation path into `--jobs=0`.

## Traceability

- Kept the V1 shares-path clamp because `F-001` identifies the reported
  Kubernetes `cpu.shares = 2` failure and `PO-2` proves the clamped result is
  `1`.
- Kept the V1 quota-path clamp because `F-002` identifies the same zero risk for
  `0 < quota < period` and `PO-3` proves the clamped result is `1`.
- Kept the V1 `_cpu_count()` guard because `F-003` shows that final
  auto-detection must enforce positivity even if a helper supplies zero, and
  `PO-5` proves that `max(1, min(cpu_share, cpu_count))` cannot return zero.
- Made no broader cgroup parsing or filesystem changes because `F-004` and
  `PO-7` mark malformed files, unreadable files, and zero periods outside the
  public issue's domain.
- Made no API, command-line, or test changes because `F-005`, `PO-6`, and
  `PO-8` show that V1 preserves the public surface while satisfying the
  positive-worker obligation.

## Verification status

The FVK proof is constructed, not machine-checked. The artifacts include exact
`kompile`, `kast`, and `kprove` commands, but they were intentionally not run in
this session.
