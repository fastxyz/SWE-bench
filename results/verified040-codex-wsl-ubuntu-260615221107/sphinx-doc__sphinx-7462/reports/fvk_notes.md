# FVK Notes

## Decisions

D1. Kept the V1 empty tuple fix.

- Trace: `fvk/FINDINGS.md` F1; `fvk/PROOF_OBLIGATIONS.md` PO1 and PO4.
- Reason: public intent requires `Tuple[()]` to render without `IndexError` and
  with literal `()` punctuation. V1's explicit empty tuple branch discharges
  that obligation and does not alter the non-empty tuple path.

D2. Added a V2 guard to the `ast.List` branch in
`repo/sphinx/domains/python.py`.

- Trace: `fvk/FINDINGS.md` F2; `fvk/PROOF_OBLIGATIONS.md` PO2 and PO3.
- Reason: FVK's boundary-case audit found the same separator-removal idiom still
  malformed empty lists. Public tests show list literals are supported inside
  annotations through `Callable[[int, int], int]`, so the empty member
  `Callable[[], int]` must preserve `[]`. Guarding `result.pop()` with
  `if node.elts:` fixes the empty case and leaves non-empty behavior unchanged.

D3. Made no other production-code changes.

- Trace: `fvk/FINDINGS.md` F3 and F4; `fvk/PROOF_OBLIGATIONS.md` PO5 and PO6.
- Reason: non-empty tuple/list behavior, unsupported-syntax fallback, function
  signatures, return shape, and callsite compatibility are frame conditions. The
  audited obligations are discharged by the tuple and list changes alone.

D4. Did not run tests, Python, or K tooling.

- Trace: `fvk/FINDINGS.md` F5 and `fvk/PROOF.md` command section.
- Reason: the task forbids execution. The FVK proof is therefore labeled
  constructed, not machine-checked, and the exact future `kompile`, `kast`, and
  `kprove` commands are recorded without being executed.

## Files Changed By This FVK Pass

- `repo/sphinx/domains/python.py`: added the V2 `if node.elts:` guard in the
  `ast.List` branch; retained the V1 empty tuple branch.
- `fvk/`: added the FVK specification, findings, proof obligations, proof,
  iteration guidance, adequacy audit, compatibility audit, and K-style formal
  core.
- `reports/fvk_notes.md`: this decision trace.
