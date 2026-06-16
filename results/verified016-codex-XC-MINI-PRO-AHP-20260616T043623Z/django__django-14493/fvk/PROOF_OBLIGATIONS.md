# FVK Proof Obligations

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Model

Let `P` be `self.max_post_process_passes` with `P >= 0`.

Let `B = [b1, b2, ...]` be the finite sequence of per-pass booleans produced by the repeated calls to `_post_process()` after the initial pass, where each `bi` is the OR of all `subst` values yielded during that repeated pass.

Let `Final(P, B)` be the value of `substitutions` at the final `if substitutions:` check in V1:

- `Final(0, B) = False`.
- `Final(P, False :: Btail) = False` for `P > 0`, because the loop breaks after the first no-substitution pass.
- `Final(1, True :: Btail) = True`.
- `Final(P, True :: Btail) = Final(P - 1, Btail)` for `P > 1`.

The max-exceeded result is yielded exactly when `Final(P, B) == True`.

## PO1: Bound Local At Final Branch

Statement: For all `P >= 0`, the local variable `substitutions` is bound before the final `if substitutions:` branch is evaluated.

Evidence: SPEC ledger I1, I3, and I4.

V1 discharge condition: the assignment `substitutions = False` before the `for i in range(self.max_post_process_passes):` loop creates a binding on the zero-iteration path. On positive-pass paths, the in-loop assignment also binds the value.

Expected proof result: discharged.

## PO2: Zero-Pass No-Crash And No Max-Exceeded Result

Statement: If `P == 0`, the repeated-pass loop executes zero iterations, `Final(0, B) = False`, and the method does not evaluate an unbound local or yield the synthetic max-exceeded `RuntimeError`.

Evidence: SPEC ledger I1, I2, I3, and I4.

V1 discharge condition: the pre-loop initializer sets the branch value to `False`.

Expected proof result: discharged.

## PO3: Positive-Pass Behavioral Preservation

Statement: For all `P > 0`, V1 has the same repeated-pass branch behavior as the pre-V1 algorithm on paths where the pre-V1 algorithm did not raise an unbound local.

Evidence: SPEC ledger I5 and I6; Findings F3.

V1 discharge condition: the first statement of each loop iteration remains `substitutions = False`, so the new pre-loop value is overwritten before any positive-pass `_post_process()` result contributes to the final branch.

Expected proof result: discharged.

## PO4: Max-Exceeded Exactness For Positive Passes

Statement: For `P > 0`, the method yields `('All', None, RuntimeError('Max post-process passes exceeded.'))` exactly when each of the `P` allowed repeated passes reports at least one substitution, so the loop exhausts without encountering a false pass.

Evidence: SPEC ledger I5 and I6.

V1 discharge condition: the OR accumulation and `if not substitutions: break` logic are unchanged.

Expected proof result: discharged.

## PO5: Initial-Pass Frame Condition

Statement: The fix does not alter the initial `_post_process()` pass, the collection of adjustable paths, the collection of processed adjustable paths, the `hashed_files` update, or the final yield of processed adjustable files.

Evidence: SPEC ledger I5, I6, and I8; Findings F2.

V1 discharge condition: the diff adds a single local assignment after the initial pass and before the repeated-pass loop.

Expected proof result: discharged by source inspection and the source-level frame.

## PO6: Public Compatibility Frame Condition

Statement: The fix does not alter `post_process()`'s signature, yielded item shape, virtual dispatch arguments, subclass override requirements, or `collectstatic` consumer protocol.

Evidence: SPEC ledger I7; Findings F4.

V1 discharge condition: the diff changes no function definitions and no call sites.

Expected proof result: discharged by source inspection.

## K Claim Mapping

The formal core is written in:

- `fvk/mini-staticfiles.k`
- `fvk/staticfiles-spec.k`

Claims map to obligations as follows:

- `V1_ZERO_PASS` discharges PO1 and PO2.
- `LEGACY_ZERO_PASS_REPRODUCES_BUG` records the adversarial pre-V1 symptom from Findings F1.
- `V1_POSITIVE_PASS` and `LEGACY_POSITIVE_PASS` discharge PO3 by showing the same abstract result for `P > 0`.
- `V1_MAX_EXCEEDED` discharges PO4.

PO5 and PO6 are source-level frame obligations outside the reduced K fragment; they are discharged by the one-line diff and the unchanged public signatures/calls.
