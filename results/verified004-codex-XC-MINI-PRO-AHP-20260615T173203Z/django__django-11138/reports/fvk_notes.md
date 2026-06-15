# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not surface a production-code defect that
requires another patch.

## Trace to findings and proof obligations

* MySQL source timezone handling is kept as V1 implemented it because
  `fvk/FINDINGS.md` F-001 identifies the pre-fix hardcoded UTC source as the
  issue, and `fvk/PROOF_OBLIGATIONS.md` PO1-PO3 require exactly the V1 behavior:
  source is `connection.timezone_name`, and equal source/target timezones skip
  `CONVERT_TZ()`.
* Oracle source timezone handling is kept because F-002 classifies the same
  source-timezone problem as applying across datetime conversion helpers, and
  PO1, PO2, and PO4 require conversion from `connection.timezone_name` to the
  requested timezone with a no-op when they match.
* SQLite's changed helper arity and parsing protocol are kept because F-003
  names producer/consumer consistency as the main SQLite risk, and PO5-PO6 show
  V1 updates both generated SQL and registered Python UDFs to pass and consume
  `(source, target)` consistently.
* The broader cast/extract/trunc coverage is kept because F-002 and PO7 trace
  the public docs for `__date`, `__time`, `Extract`, `Trunc`, and
  `QuerySet.datetimes()` to one shared source-to-target conversion obligation.
  A narrower `__date`-only patch would leave PO7 open.
* PostgreSQL remains unchanged because `fvk/INTENT_SPEC.md` item 7 and
  `fvk/SPEC.md` mark it outside this repair scope: it supports timezone-aware
  storage and Django disallows per-database `TIME_ZONE` for that backend.
* No compatibility patch is needed because `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
  and PO8 show public `datetime_*_sql()` signatures are unchanged. The only
  arity change is the private SQLite UDF protocol, already covered by PO5.
* No additional code was added for actual DST/timezone arithmetic because F-004
  and PO9 classify that as an external proof boundary delegated to pytz and the
  databases, not as the defect reported in this issue.

## Execution status

No tests, Python, or K tools were run. The proof artifacts include the commands
that should be run later in a K-capable environment, but this benchmark
workspace forbids executing them.
