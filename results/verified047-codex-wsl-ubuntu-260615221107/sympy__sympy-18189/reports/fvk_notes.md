# FVK Notes

## Decisions

1. Kept the V1 `permute` propagation.

   Reason: FVK finding F-001 identifies the reported bug as the recursive
   `syms` remapping path dropping `permute=True`. Proof obligation PO-2 requires
   the recursive canonical solve to receive the caller's `permute` value, and
   PO-4 requires the same forwarding to preserve the default `permute=False`
   behavior. The current source satisfies both by calling
   `diophantine(eq, param, permute=permute)`.

2. Improved V1's tuple remapping.

   Reason: FVK finding F-002 shows that the V1 remap formula was only
   accidentally correct for the public two-variable swap. For a longer
   requested order, the recursive solve returns canonical-order tuples, so PO-3
   requires mapping canonical `var` symbols to tuple indexes and iterating the
   requested `syms` sequence. The source now builds
   `dict(zip(var, range(len(var))))` and returns
   `tuple(t[dict_sym_index[i]] for i in syms)`.

3. Did not edit any other solver paths.

   Reason: FVK finding F-003 and proof obligation PO-6 mark the full algebraic
   Diophantine solver as an abstraction boundary for this audit. The issue and
   the proved obligations concern the wrapper's `syms` remapping path. No
   finding justified changes to `classify_diop`, `diop_solve`, denominator
   handling, or the permutation generator helpers.

4. Did not edit tests or run commands.

   Reason: the task forbids modifying tests and forbids running tests, Python,
   or K tooling. `fvk/PROOF.md` records the `kompile`, `kast`, and `kprove`
   commands that should be run later in a suitable environment, but this FVK
   pass remains constructed and not machine-checked.

## Source Changes Since V1

- `repo/sympy/solvers/diophantine.py`: changed the `syms != var` remapping
  branch to index recursive canonical tuples by canonical `var` positions and
  emit entries in requested `syms` order, while preserving V1's forwarded
  `permute` argument.

## Artifacts

- `fvk/SPEC.md`: public intent ledger, intent-only contract, formal English
  claims, and adequacy check.
- `fvk/FINDINGS.md`: resolved source findings F-001 and F-002 plus solver
  abstraction boundary F-003.
- `fvk/PROOF_OBLIGATIONS.md`: PO-1 through PO-6, linking intent, source lines,
  and proof duties.
- `fvk/PROOF.md`: constructed proof, V0/V1 counterexample mechanisms, and
  would-run K commands.
- `fvk/ITERATION_GUIDANCE.md`: V2 guidance, residual risk, and no-test-deletion
  recommendation.
- `fvk/mini-diophantine.k` and `fvk/diophantine-syms-spec.k`: the mini K
  semantics and claims referenced by the markdown artifacts.
