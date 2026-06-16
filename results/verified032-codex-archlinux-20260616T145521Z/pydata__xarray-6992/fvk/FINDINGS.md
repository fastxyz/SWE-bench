# FVK Findings

Status: constructed, not machine-checked.

## F-001: Pre-fix reset_index propagated a stale coordinate name

Evidence: E-1, E-2, E-3; obligations PO-2, PO-3, PO-4, PO-5.

Input/state:

- `V = C = {z, a, b}`
- `D = {z}`
- `N = {}`

Observed pre-fix transition:

- `V' = {a, b}`
- old formula `C_old' = C union N = {z, a, b}`
- `z notin V'` but `z in C_old'`
- `len(data_vars) = len(V') - len(C_old') = 2 - 3 = -1`

Expected:

- `C' = {a, b}`
- `len(data_vars) = 0`
- repr and data-variable mapping operations do not raise a negative-length
  `ValueError`.

Classification: code bug in the producer of `_coord_names`.

Resolution: V1 changes `coord_names` to
`self._coord_names & variables.keys() | set(new_variables)`, discharging PO-2
through PO-5.

## F-002: V1 preserves surviving level coordinates

Evidence: E-4, E-5; obligations PO-6, PO-7, PO-8.

Input/state:

- Any old coordinate name `k` with `k in C` and `k in V'`.
- Any replacement index variable name `k in N`.

Observed V1 transition:

- `k in C intersect V'` implies `k in C'`.
- `k in N` implies `k in C'`.

Expected:

- Surviving coordinate variables remain coordinates.
- Replacement index variables created by partial multi-index-level resets are
  coordinates.

Classification: confirmation finding. No source change needed.

## F-003: Changing only DataVariables.__len__ would be incomplete

Evidence: E-1 and E-7; obligations PO-2 and PO-4.

Alternative considered:

- Replace `DataVariables.__len__` with an iterator count or
  `len(set(_variables) - _coord_names)`.

Why rejected:

- It would satisfy PO-4 locally, but it would not satisfy PO-2. A stale
  coordinate name could still remain in `_coord_names`, affecting coordinate
  mapping lengths, lookup behavior, and later internal consumers.

Classification: rejected alternative.

## F-004: No remaining blocking finding from the FVK audit

Evidence: all proof obligations.

The V1 source expression discharges the stated obligations for the audited
state transition. The proof is constructed only; machine checking was not run
because this task forbids K tooling.

Residual risk:

- The mini-K model abstracts away pandas index value contents and proves only
  the name-set invariant relevant to this issue.
- Termination of `reset_index` is not separately proved.
