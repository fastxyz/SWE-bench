# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | prompt | "incomplete results depending on syms order with permute=True" | Solution-set completeness under `permute=True` must not depend on the order chosen for `syms`. | Encoded by Claim C2 and Claim C4. |
| E2 | prompt | `diophantine(..., syms=(m,n), permute=True)` displays eight tuples. | The issue equation's `permute=True` canonical result includes the eight signed/permuted solutions. | Encoded by `canonical(pow4_mn_2_3, tparam, true) => pow4_signed_mn` and Claim C4. |
| E3 | prompt | `diophantine(..., syms=(n,m), permute=True)` displays `{(3, 2)}` as the bad output. | This is SUSPECT legacy behavior and must not be specified as correct. | Recorded as the pre-fix counterexample in `FINDINGS.md`. |
| E4 | prompt hint | "`permute=True` is lost when `diophantine` calls itself" | The recursive call in the `syms` normalization branch must receive the caller's `permute` value. | Encoded by Claim C2. |
| E5 | docstring | "`syms` is an optional list of symbols which determines the order of the elements in the returned tuple." | Reordered `syms` should remap tuple positions, not change the solution set. | Encoded by Claim C2 and the `reorder` abstraction. |
| E6 | docstring | "If `permute` is set to True then permutations ... will be returned when applicable." | `permute=True` is part of the canonical solve contract. | Encoded by Claim C1 and Claim C2. |
| E7 | implementation | V1 calls `diophantine(eq, param, permute=permute)` in the `syms != var` branch. | Candidate implementation preserves the symbolic `PERM` flag across the recursive solve. | Modeled by `mini-python.k`; proof constructed in `PROOF.md`. |
| E8 | implementation | Other public calls still use the same `diophantine(eq, param, syms=None, permute=False)` signature defaults. | Public API and default behavior must be frame-preserved. | Audited in `PUBLIC_COMPATIBILITY_AUDIT.md` and Claim C3/C5. |
