# Iteration Guidance

Status: V1 stands unchanged after FVK audit.

## Decision

Do not edit production source beyond the V1 fix.

Reason: Findings F-1 and F-2 identify the two public whitespace bugs, and PO-1 through PO-4 are discharged by the V1 token-joining implementation. PO-5 confirms the multi-column delimiter and public call shape are preserved.

## Rejected Follow-up Change

Do not add stripping or broader normalization of pre-spaced suffix fragments in this pass.

Reason: F-4 records that the sourced public producer emits `''` or `DESC`, not pre-spaced suffix fragments. Changing behavior for arbitrary pre-spaced fragments would exceed the public issue evidence and could affect direct helper users without a demonstrated need.

## Suggested Future Tests

If test edits were allowed in a normal development session, targeted tests would assert:

- `Columns(..., col_suffixes=['DESC'])` renders `"name" DESC`.
- `Columns(..., col_suffixes=[''])` renders `"name"`.
- `IndexColumns(..., opclasses=['text_pattern_ops'], col_suffixes=[''])` renders `"name" text_pattern_ops`.
- `IndexColumns(..., opclasses=['text_pattern_ops'], col_suffixes=['DESC'])` renders `"name" text_pattern_ops DESC`.

These should be added to helper or schema SQL tests, not by modifying tests in this benchmark session.

## Machine-check Follow-up

Run later, outside this no-execution benchmark session:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/index-columns-spec.k
kprove fvk/index-columns-spec.k
```

Keep all tests until the K proof is actually machine-checked and any real Django test suite is run in an environment that supports execution.
