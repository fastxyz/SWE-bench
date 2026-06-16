# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not identify a source-level gap in the
fix for the public issue.

## Trace to Findings and Proof Obligations

- The issue's root bug is captured in `fvk/FINDINGS.md` F1 and proof
  obligations PO1-PO2: Django generated `db` and `passwd` from standard
  settings. V1 already changes those writes to `database` and `password`.
- The decision not to edit source further is captured in F2 and PO1-PO2: the
  V1 source now satisfies the standard-settings deprecation obligation.
- The decision not to normalize user-supplied legacy `OPTIONS['db']` or
  `OPTIONS['passwd']` is captured in F3 and PO3-PO4. Public docs make
  `OPTIONS` a pass-through driver-options channel, and the issue points to
  Django's own generated kwargs rather than arbitrary user-supplied aliases.
- The decision not to change unrelated behavior is captured in PO6. The V1 diff
  only changes the two deprecated key names and leaves host, port, user,
  charset, conversion, client flag, isolation level validation, and options
  merging unchanged.
- The decision not to run tests or K tooling is captured in F4 and PO7, matching
  the benchmark constraints.

## Files

- Source code: no changes beyond the existing V1 edit in
  `repo/django/db/backends/mysql/base.py`.
- FVK artifacts: added under `fvk/`, including the five requested reports and
  the constructed `.k` core required by the FVK method.

## Verification Status

The proof is constructed, not machine-checked. The recorded commands in
`fvk/PROOF.md` should be run only in an environment where K tooling is available
and execution is permitted.
