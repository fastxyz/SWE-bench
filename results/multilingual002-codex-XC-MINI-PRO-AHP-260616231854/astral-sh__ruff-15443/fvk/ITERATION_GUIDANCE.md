# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged. The audit found no remaining source defect that is justified by public intent and not already discharged by the V1 edit.

## Why No Source Edit Is Needed

- F-01 is resolved by PO-01 and PO-04: explicit `builtins.exec` and `builtins.open` are now accepted.
- F-02 is resolved by PO-03 and PO-06: singular `builtin.exec` and `builtin.open` are now rejected.
- F-03 is resolved by PO-07: existing `PTH123` exclusions are preserved.
- F-04 is resolved by PO-09: no exact `"builtin"` matcher remains in the audited source slice.
- PO-08 shows there is no public API or dispatch compatibility change to repair.

## Rejected Follow-Up Changes

- Re-adding `"builtin"` as an alias was rejected because it would reintroduce F-02.
- Replacing the raw `S102` pattern with `SemanticModel::match_builtin_expr` was rejected as unnecessary for this issue. The current pattern already matches Ruff's established `["" | "builtins", ...]` convention and keeps the fix smaller.
- Changing `PTH123` argument filtering was rejected because F-03 and PO-07 classify it as preserved behavior outside the reported bug.

## Recommended Tests If Test Edits Become Allowed

Do not edit tests in this benchmark. If a future task allows tests, add public regression coverage for:

- `import builtins; builtins.open(...)` emits `PTH123`.
- `import builtins; builtins.exec(...)` emits `S102`.
- `import builtin; builtin.open(...)` does not emit `PTH123`.
- `import builtin; builtin.exec(...)` does not emit `S102`.
- Optional alias coverage: `import builtins as builtin_alias; builtin_alias.open(...)` and `builtin_alias.exec(...)` should follow the resolved `builtins` module.

## Later Machine Check

Run the commands recorded in `fvk/PROOF.md` only in an environment where K tooling is available. Until then, treat the proof as constructed but not machine-checked and do not remove any tests based on it.
