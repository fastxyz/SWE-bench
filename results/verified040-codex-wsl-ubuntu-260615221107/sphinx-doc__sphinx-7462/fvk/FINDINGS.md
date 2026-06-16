# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F1: Empty Tuple Crash In Original Code

- Classification: code bug, fixed by V1 and retained in V2
- Input: `_parse_annotation("Tuple[()]")`
- Observed before V1: the `ast.Tuple` branch initialized `result = []`, skipped
  the loop because `node.elts` was empty, then called `result.pop()`, producing
  `IndexError: pop from empty list`.
- Expected: docs build and render the valid annotation form `Tuple[()]`.
- Evidence: E1, E2, E3
- Related proof obligations: PO1, PO4
- Resolution: V1 added an explicit empty tuple branch returning `(` and `)`.
  V2 keeps that branch.

## F2: Empty List Delimiter Loss In V1

- Classification: code bug found by FVK audit, fixed by V2
- Input: `_parse_annotation("Callable[[], int]")`
- Observed in V1 by symbolic inspection: the `ast.List` branch initialized
  `result` with `[`, skipped the loop because `node.elts` was empty, then called
  `result.pop()`. That pop removed the opening bracket rather than a trailing
  separator. The branch then appended `]`, so the inner empty list contributed
  only `]` instead of `[]`.
- Expected: the supported list delimiter family preserves both delimiters, so
  the inner list contributes `[` followed by `]`.
- Evidence: E2, E5
- Related proof obligations: PO2, PO3, PO4
- Resolution: V2 guards the list branch cleanup with `if node.elts:`. Empty
  lists keep the opening bracket and append the closing bracket; non-empty lists
  still remove the trailing separator.

## F3: Non-empty Separator Behavior Must Be Preserved

- Classification: frame condition, discharged
- Inputs: `_parse_annotation("Tuple[int, int]")`,
  `_parse_annotation("Callable[[int, int], int]")`, and
  `_parse_annotation("List[int]")`
- Observed risk: changing delimiter handling could add extra parentheses,
  retain trailing commas, or remove brackets for existing non-empty annotations.
- Expected: existing public-test output shape remains unchanged.
- Evidence: E4, E5, E6
- Related proof obligations: PO3, PO4
- Resolution: V2 changes only empty-collection cleanup. For non-empty lists,
  `if node.elts:` is true and the same separator pop occurs. For non-empty
  tuples, V1's existing non-empty branch remains unchanged.

## F4: Unsupported Syntax Fallback Is Outside The Fix

- Classification: frame condition, discharged
- Input class: annotation AST nodes not handled by the existing `unparse()`
  branches
- Observed: unsupported nodes raise `SyntaxError` inside `unparse()` and are
  converted to one fallback pending xref for the original annotation string.
- Expected: no change, because the public issue concerns supported empty
  delimiter syntax rather than unsupported AST expansion.
- Evidence: E7
- Related proof obligations: PO5
- Resolution: no source change to fallback behavior.

## F5: Proof Construction Not Machine-Checked

- Classification: proof status / execution gap
- Input: all formal claims in `fvk/python-annotation-spec.k`
- Observed: the proof and K artifacts were constructed manually as required by
  FVK, but `kompile`, `kast`, and `kprove` were not run because the task forbids
  K tooling and repository code execution.
- Expected: artifacts explicitly mark this status and provide commands for a
  future machine check.
- Related proof obligations: PO1 through PO6
- Resolution: commands are recorded in `fvk/PROOF.md`; no tests are removed.
