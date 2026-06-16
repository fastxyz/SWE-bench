FVK decision:

V1 stands unchanged. The audit found the reported failure is exactly the
metadata lookup on the plain partial passed to user decorators, and V1 copies
wrapper assignments onto that partial before any decorator receives it.

Decision trace:

- Kept the V1 source edit in `repo/django/utils/decorators.py` because F-001
  identifies the pre-fix bug and PO-001 shows `wraps(method)` copies standard
  wrapper assignments onto the partial before decorator application.
- Did not add further source changes for the `logger` example because F-002 and
  PO-002 discharge the `func.__name__` lookup obligation when the original
  method has `__name__`.
- Did not replace the partial with a nested function because F-003 and PO-003
  show that keeping the partial preserves the existing no-`self` call binding
  and call target while adding metadata.
- Did not alter decorator iteration or wrapper-finalization code because F-003,
  PO-004, and PO-005 show those existing behaviors are framed unchanged.
- Did not change public API or validation branches because F-006 and PO-006 show
  the diff is local to decorator-input metadata and does not affect
  `method_decorator()`'s signature, class-decoration errors, or non-callable
  attribute errors.
- Did not remove or modify tests because F-005 and PO-007 state the proof is
  constructed, not machine-checked, and this task forbids test edits.

Artifacts written:

- `fvk/SPEC.md` records the intent-first spec, evidence ledger, adequacy audit,
  and public compatibility audit.
- `fvk/FINDINGS.md` records resolved findings and residual proof honesty risks.
- `fvk/PROOF_OBLIGATIONS.md` records PO-001 through PO-007 and the commands to
  machine check later.
- `fvk/PROOF.md` gives the constructed proof that V1 satisfies those
  obligations.
- `fvk/ITERATION_GUIDANCE.md` records that no further repair is recommended.
- `fvk/mini-method-decorator.k` and `fvk/method-decorator-spec.k` provide the
  lightweight abstract formal core referenced by the proof artifacts.

No commands that execute tests, Python code, or K tooling were run.
