# FVK Findings

Status: constructed, not machine-checked. These findings are derived from public intent, source inspection, and the constructed proof obligations only. No tests, Python, or K commands were run.

## F-1: Pre-fix normal descending indexes missed a separator

Input class: `Index(fields=['-name'], name='idx')` on the normal `Columns` rendering path.

Observed in V0 by source inspection: `Columns.__str__()` used `quote_name(column) + self.col_suffixes[idx]`, so a quoted column token and suffix token `DESC` would render as `"name"DESC`.

Expected by INT-1: `"name" DESC`.

V1 status: fixed. `Columns.__str__()` now joins `(quoted_column, suffix)` while filtering empty suffixes, satisfying PO-1 and PO-2.

## F-2: Pre-fix PostgreSQL opclass indexes emitted a trailing space for empty suffixes

Input class: `Index(fields=['name'], name='idx', opclasses=['text_pattern_ops'])` on the PostgreSQL `IndexColumns` path.

Observed in V0 by source inspection: `IndexColumns.__str__()` always formatted `col_suffixes[idx]` with a leading separator. Because ascending order is represented by `''`, the rendered column became `"name" text_pattern_ops `.

Expected by INT-2: `"name" text_pattern_ops`.

V1 status: fixed. `IndexColumns.__str__()` now joins `(quoted_column, opclass, suffix)` while filtering empty suffixes, satisfying PO-3.

## F-3: Opclass plus descending order remains correctly tokenized

Input class: `Index(fields=['-name'], name='idx', opclasses=['text_pattern_ops'])`.

Expected by INT-3: `"name" text_pattern_ops DESC`.

V1 status: confirmed by source-level proof obligation PO-4. The V1 renderer keeps all three non-empty tokens and inserts a single space between adjacent tokens.

## F-4: Pre-spaced or whitespace-only suffix fragments are not part of the sourced public contract

Input class: direct helper use such as `Columns(..., col_suffixes=[' DESC'])` or whitespace-only suffixes.

Observed: the public producer `Index.fields_orders` emits `''` or `DESC`, not pre-spaced fragments. No in-repo public caller was found that passes pre-spaced suffixes.

Expected: no additional source change is justified by the public issue. Broadening the patch to strip or normalize arbitrary user-supplied fragments would be a behavior change outside the evidenced domain.

V1 status: accepted as unchanged. This is an out-of-domain compatibility note, not a code bug.

## F-5: Proof is constructed but not machine-checked

Input class: all obligations in `fvk/PROOF_OBLIGATIONS.md`.

Observed: the task forbids running tests, Python, `kompile`, or `kprove`.

Expected: artifacts must contain exact commands and label the proof honestly.

V1 status: residual verification risk only. Code decisions do not depend on hidden tests or machine-check results.

## F-6: No public compatibility break found

Input class: public and internal callers of `Columns`, `IndexColumns`, `_index_columns()`, and `_create_index_sql()`.

Observed: V1 changes only string assembly inside `__str__()` and leaves method signatures, constructor signatures, dispatch, and return type unchanged.

Expected: callers continue passing the same arguments and receiving a string representation.

V1 status: confirmed by PO-5 and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.
