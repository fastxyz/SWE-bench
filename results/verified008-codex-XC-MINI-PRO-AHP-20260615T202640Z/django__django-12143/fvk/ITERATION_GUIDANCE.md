# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

Keep V1 source unchanged.

FVK findings F1, F2, and F3 support the no-change decision:

- F1 shows the reported prefix metacharacter bug is addressed by V1.
- F2 shows no same-pattern sibling occurrence was found under the allowed
  `repo/django` source tree.
- F3 shows the patch preserves public compatibility and internal caller shape.

## Recommended next steps outside this benchmark

When an execution environment is available, add or run tests covering at least:

```text
prefix = "a+b", key = "a+b-0-id"       -> selected
prefix = "a+b", key = "ab-0-id"        -> not selected
prefix = "a.b", key = "a.b-0-id"       -> selected
prefix = "[x]", key = "[x]-0-id"       -> selected
```

If K is available, run the commands listed in `fvk/PROOF.md` after adapting the
mini model to the local K installation.

No production source edit is recommended by this FVK pass.

