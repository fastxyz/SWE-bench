# Iteration Guidance

Status: constructed, not machine-checked.

Decision:

- Keep the V1 source code unchanged.

Reason:

- F-002 discharges the reported quantifier case through O2/O3/O6.
- F-003 discharges backward-compatible top-level CSV behavior through O3/O4/O5/O7.
- F-004 discharges the issue's requested escape workaround through O2/O3.
- F-005 discharges public compatibility through O8/O10.

Recommended future work:

- Update or replace the SUSPECT public test identified in F-001 during normal test maintenance. This task forbids test edits.
- Consider documenting escaped commas for `regexp_csv` options, as noted in F-006.
- If the project later decides to deprecate comma-separated regex lists, do that as a separate compatibility change with explicit deprecation messaging.

Do not:

- Do not restore the legacy behavior that splits `(foo{1,3})`.
- Do not change generic CSV parsing for non-regex options.
- Do not change `regexp_paths_csv` without a separate issue and compatibility audit.
