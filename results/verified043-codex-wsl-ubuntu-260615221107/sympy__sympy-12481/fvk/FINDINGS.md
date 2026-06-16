# FVK Findings

Status: constructed from static analysis and formal reasoning. No code or verification tooling was run.

## F-1: Global Duplicate Rejection Blocked Valid Cyclic Input

Classification: code bug, resolved by V1 and clarified by V2.

Input: `Permutation([[0, 1], [0, 1]])`

Observed before the fix: the constructor flattened the cyclic input, found duplicate entries, and raised `ValueError`.

Expected from public intent: apply the first cycle `[0, 1]`, then apply the second `[0, 1]`, yielding identity `[0, 1]`.

Root cause: the same duplicate check was used for array-form input and cyclic list input. Array-form duplicates are invalid, but repeated elements across separate cycles are precisely the non-disjoint cycle case the issue says to allow.

Resolution: cyclic list input bypasses the array duplicate guard and proceeds to the existing left-to-right `Cycle` fold.

Relevant obligations: PO-1, PO-2, PO-3, PO-4.

## F-2: Legacy Public Test Conflicts With Issue Intent

Classification: suspect legacy test, not a code blocker.

Input: `Permutation([[1], [1, 2]])`

Legacy public-test expectation: raises `ValueError`.

Expected from public issue intent: this is non-disjoint cyclic list input, so it should be composed left to right. The singleton `[1]` is identity/sizing input and `[1, 2]` then swaps `1` and `2`.

Resolution: test files were not modified, but the FVK spec treats this expectation as SUSPECT and does not use it to veto the prompt-derived behavior.

Relevant obligations: PO-1, PO-2, PO-6.

## F-3: Array-Form Duplicate Rejection Must Be Preserved

Classification: frame condition, confirmed.

Input: `Permutation([1, 1, 0])`

Expected: still raises repeated-elements `ValueError`.

Reason: the issue only concerns repeated elements across separate cycles. Array form remains a one-to-one image list, so duplicates are invalid.

Resolution: V2 keeps the duplicate guard for `not is_cycle` inputs.

Relevant obligations: PO-5.

## F-4: Individual Cycle Validity Remains Out Of Scope For Relaxation

Classification: preserved precondition, confirmed.

Input: cyclic list containing a single invalid cycle such as `[[1, 2, 1]]`

Expected: still rejected by `Cycle(*ci)` because one cycle cannot contain repeated elements.

Reason: the public issue removes disjointness between cycles, not uniqueness within a cycle.

Resolution: V2 leaves `Cycle` validation untouched.

Relevant obligations: PO-7.

## F-5: Proof Is Constructed But Not Machine-Checked

Classification: proof capability and environment limitation.

The K artifacts and proof commands are emitted, but this task explicitly forbids running K tooling. The proof is therefore constructed, not machine-checked.

Resolution: keep tests until the emitted `kompile` and `kprove` commands are run in an environment with K installed and return `#Top`.

Relevant obligations: PO-8.
