# Excerpt: results/.../fvk/FINDINGS.md  F7 — the pivotal "could not reproduce" moment

This is the closest the artifacts come to noticing V1 is misdirected. The agent
admits its V1 mechanism (operand-sharing -> set_values) does NOT reproduce the bug,
then REINTERPRETS that as "V1 is correct under both readings / defense-in-depth"
instead of as a signal that the real fix lies elsewhere (get_order_by). Classic
inversion of the "hard-to-reproduce/spec => bug" heuristic into false reassurance.

## FINDINGS.md:85-95 (verbatim core)
```
## F7 (warning) — Spec-difficulty signal: the base ALSO clones at the mutation site
- Observation while building the model: the audited tree's
  get_combinator_sql (compiler.py:429) already does
  compiler.query = compiler.query.clone() before set_values(). In isolation, that
  clone-at-the-mutation-site already prevents set_values() from reducing a shared
  combined query: the original operand keeps its full column list.
- Consequence (honest): With that line present, I could NOT construct a concrete
  input that reproduces the reported crash purely through the set_values path - the
  combined operands are never mutated in place. That difficulty is itself a finding
  (FVK "if it's hard to reproduce/spec, say so"). Two readings, both leaving V1 correct:
```
=> Both "readings" the agent lists keep V1 correct. It never entertains the third
reading: that the crash path is `get_order_by` raising on an un-aliased ORDER-BY
column that is not in the (reduced) select list, which V1's clone does NOT address.

## FINDINGS.md:144-150  PD-3 — the agent flags the ADJACENT column-alignment area
... but explicitly sets it aside as "separate from #10554" and never connects it to
get_order_by:
```
PD-3 (unrelated latent bug, out of scope). ... get_combinator_sql's
`if not compiler.query.values_select and self.query.values_select` guard
(compiler.py:428) ... a column-count mismatch ... This is separate from #10554 and
from V1; left untouched per "fix the described issue only".
```
This is the nearest miss: the agent is staring at the column-list/ORDER-BY alignment
region but rules it out of scope, and never reaches the get_order_by raise.
