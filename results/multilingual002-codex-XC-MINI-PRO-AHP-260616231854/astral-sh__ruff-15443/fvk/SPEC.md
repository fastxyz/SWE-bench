# FVK Spec

Status: constructed, not machine-checked.

## Scope

This audit covers the V1 changes for:

- `S102` in `repo/crates/ruff_linter/src/rules/flake8_bandit/rules/exec_used.rs`
- `PTH123` in `repo/crates/ruff_linter/src/rules/flake8_use_pathlib/rules/replaceable_by_pathlib.rs`

The observable behavior is whether each rule emits a diagnostic for a call target after Ruff resolves that target to qualified-name segments.

## Intent Spec

1. `S102` must report use of the builtin `exec` function when the resolved call target is unqualified `exec` or explicitly qualified as `builtins.exec`.
2. `S102` must not report `builtin.exec`; `builtin` is not the Python standard-library module named in the issue.
3. `PTH123` must report use of builtin `open` when the resolved call target is unqualified `open` or explicitly qualified as `builtins.open`, subject to the rule's existing exclusions for file descriptors and unsupported `Path.open` arguments.
4. `PTH123` must not report `builtin.open`; `builtin` is not the Python standard-library module named in the issue.
5. The fix must not change public APIs, rule codes, diagnostics messages, or the existing `PTH123` exclusions for `closefd`, `opener`, and file-descriptor arguments.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
|---|---|---|---|---|
| E1 | prompt | "PTH123 and S102 check `builtin` instead of `builtins`" | Use module segment `builtins` for explicit builtin-module references, not `builtin`. | Encoded in K claims C-S102-BUILTINS and C-PTH123-BUILTINS. |
| E2 | prompt | False negative example imports `builtins`, calls `builtins.open(...)`, and `builtins.exec(...)`; Ruff previously passed. | Emit `PTH123` and `S102` for those explicit `builtins` calls. | Encoded in claims and checked against V1 source. |
| E3 | prompt | False positive example imports `builtin` and Ruff previously reported both rules. | Do not emit these rules for `builtin.open(...)` or `builtin.exec(...)`. | Encoded in claims and checked against V1 source. |
| E4 | source | `SemanticModel::resolve_builtin_symbol` and `match_builtin_expr` match `["" | "builtins", name]`. | Preserve unqualified builtin binding behavior while accepting explicit `builtins`. | Encoded in direct-call claims. |
| E5 | source | `PTH123` comments document `closefd`, `opener`, and file-descriptor exclusions. | Preserve these pre-existing frame conditions. | Encoded in PTH123 exclusion claims. |

## Formal Core

The mini K fragment is in `fvk/mini-ruff-calls.k`. It abstracts Ruff's call checking to:

- a rule id: `S102` or `PTH123`
- a resolved qualified name: `qname(module, member)`
- for `PTH123`, three existing exclusion flags: non-default `closefd`, non-default `opener`, and file descriptor
- an observable decision: `emit` or `noEmit`

The reachability claims are in `fvk/builtin-module-spec.k`. They specify:

- `S102` emits for `qname("builtins", "exec")` and `qname("", "exec")`
- `S102` does not emit for `qname("builtin", "exec")`
- `PTH123` emits for `qname("builtins", "open")` and `qname("", "open")` when all exclusion flags are false
- `PTH123` does not emit for `qname("builtin", "open")`
- `PTH123` does not emit when any preserved exclusion flag is true

## Formal Spec English

The K claims say exactly this: the only module prefixes that count as builtin-module references for these two rules are the empty segment used for unqualified builtin bindings and the explicit `builtins` module. The singular `builtin` module is outside the allowed set and must not cause either rule to emit. `PTH123` keeps its existing argument-compatibility exclusions.

## Spec Audit

All formal claims pass the intent adequacy gate:

- The `builtins` positive claims are entailed by E1 and E2.
- The `builtin` negative claims are entailed by E1 and E3.
- The empty-segment positive claims are entailed by E4 and preserve existing builtin-call behavior.
- The `PTH123` exclusion claims are entailed by E5 and are frame conditions over behavior not challenged by the issue.
- No ordering, precedence, output-form, loop, recursion, or public API compatibility obligation is under-specified for this fix.

## Public Compatibility Audit

V1 changes only string literals inside private rule implementations. It does not alter rule ids, exported types, function signatures, diagnostic messages, fix applicability, public call shapes, or virtual dispatch. No public callsite or override requires an update.
