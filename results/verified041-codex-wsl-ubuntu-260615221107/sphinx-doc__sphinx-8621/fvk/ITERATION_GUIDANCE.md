# Iteration Guidance

## Verdict

V1 stands unchanged. The FVK audit found no production-code defect against the
intent-derived proof obligations in `fvk/PROOF_OBLIGATIONS.md`.

## Decisions for This Iteration

- Keep `repo/sphinx/builders/html/transforms.py` unchanged after V1. F-1 and
  F-2 are closed by PO-2 and PO-4; F-3 confirms the compatibility frame through
  PO-3 and PO-7.
- Do not broaden the parser for malformed adjacent separators in this pass. F-4
  is outside the public intent domain and needs clarification before it can
  justify source behavior.
- Do not run or modify tests. The task forbids execution and test-file edits;
  F-5 and PO-8 keep all proof/test-removal claims conditional on a future
  machine check.

## Suggested Future Tests

If test editing is allowed in a normal development environment, add public tests
for the family proven here:

- `:kbd:`-``, `:kbd:`+``, and `:kbd:`^`` render as one outer `kbd` element with
  no nested blank keys.
- `:kbd:`Shift-+``, `:kbd:`Shift--``, and `:kbd:`Shift-^`` render as a compound
  with the punctuation after `Shift-` as the second key.
- `:kbd:`Control++``, `:kbd:`Control+-``, and `:kbd:`Control+^`` render as a
  compound with `+` as the separator and the final punctuation as the key.
- Existing examples `Control+X` and `M-x  M-s` remain unchanged.

## Suggested Future Clarification

Ask whether malformed adjacent separators such as `Shift- +` should be accepted
and normalized, rejected, or preserved literally. Until clarified, keep that
shape outside the verified domain.

## Reproduce the Constructed Proof Later

In an execution-capable environment:

```sh
kompile fvk/mini-keyboard.k --backend haskell
kast --backend haskell fvk/keyboard-transform-spec.k
kprove fvk/keyboard-transform-spec.k
```

Only after `kprove` returns `#Top` should any redundant-test recommendation be
treated as machine-checked.
