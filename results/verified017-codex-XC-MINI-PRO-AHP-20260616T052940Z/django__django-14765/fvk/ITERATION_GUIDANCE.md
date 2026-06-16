# ITERATION GUIDANCE

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Decision

V1 stands unchanged.

## Why No Code Edit Is Needed

- `F1` and `PO3` show the issue's core bug is resolved: non-`None` non-set
  `real_apps` values now assert instead of being converted.
- `F2` and `PO1` show `None` still creates an empty set.
- `F3` and `PO2` show empty sets are handled according to the stricter
  "when non-None" reading.
- `F4` and `PO5` show the compatibility cost for external non-set callers is
  intentional under the issue text, while source call sites remain compatible.
- `PO4` shows unrelated constructor state is preserved.

## Follow-Up Work

- In a full environment, run the commands from `fvk/PROOF.md` and require
  `kprove` to return `#Top`.
- Keep all tests until the proof is machine-checked. No test removal is part of
  this benchmark task.
- If maintainers want stronger public compatibility despite the issue's
  internal-API framing, the next design question is whether non-set external
  calls should raise `AssertionError` or a documented `TypeError`. That would
  be a different contract than the one requested here.

