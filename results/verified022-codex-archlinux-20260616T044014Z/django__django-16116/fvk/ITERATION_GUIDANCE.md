# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged. The FVK audit did not surface a source-level defect against
the public intent. The existing V1 edit is exactly the proof-relevant repair:
make `--check` imply the existing dry-run no-write mode before any writer path
is reachable.

## Trace to findings and obligations

- Keep V1 dry-run implication: justified by F-1 and discharged by PO-1 through
  PO-4.
- Keep ordinary `makemigrations` behavior unchanged: justified by I5 and PO-6.
- Do not add a formatter guard in this issue: justified by F-2. It is a possible
  cleanup, but not required to satisfy no migration-file creation/update/delete.
- Do not edit tests: justified by the task constraints and F-3.
- Keep proof caveat explicit: required by PO-8 and F-4.

## Suggested next work outside this task

1. Add a public regression test that `makemigrations --check` with detected
   changes leaves the migration directory unchanged.
2. Consider a separate cleanup to avoid calling `run_formatters([])` in dry-run
   paths, if maintainers want dry-run to avoid even empty formatter subprocesses.
3. Machine-check the K artifacts after installing K.
