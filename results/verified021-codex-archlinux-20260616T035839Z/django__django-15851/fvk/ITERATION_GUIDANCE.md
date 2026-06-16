# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged as V2.

Reason: Findings F-01 through F-05 and proof obligations PO-01 through PO-07
show that the public PostgreSQL ordering intent is met, the legacy public test
expectation is suspect, and no frame or compatibility obligation requires an
additional production-code edit.

## Recommended Follow-up Outside This Task

Do not remove tests based on this constructed proof alone. If a full environment
is available later, run the emitted K commands and the Django test suite.

The fixed public test expectation should be PostgreSQL-specific and should
assert `parameters` before `dbname`, ideally with the issue's `-c` shape.

## No Source Edits Needed

No further source change is recommended. In particular:

- Do not change the management command parser; PO-06 shows the backend is the
  correct ordering point.
- Do not change SQLite, MySQL, or Oracle clients; I-05 and PO-07 keep the fix
  PostgreSQL-specific.
- Do not replace the positional dbname with `-d`; PO-01 and PO-02 are satisfied
  by preserving the positional database argument and moving it to the end.
