## Decisions

Kept the V1 compiler fix in `repo/django/db/models/sql/compiler.py`.

Reason: `fvk/FINDINGS.md` F1 identifies the original defect as metadata
ordering being selected before `get_extra_select()` and `get_group_by()` consume
the ordering list. `fvk/PROOF_OBLIGATIONS.md` PO-1 and PO-2 require metadata
ordering to be absent before both downstream steps. The V1 guard
`self.query.group_by is None` discharges those obligations while PO-3 confirms
that default metadata ordering remains active for non-grouped queries and PO-4
confirms explicit and extra ordering are preserved.

Added a follow-up edit in `repo/django/db/models/query.py`.

Reason: `fvk/FINDINGS.md` F2 found that V1 used the documented
`query.group_by is None` sentinel in the compiler but left `QuerySet.ordered`
using a truthiness check. `fvk/PROOF_OBLIGATIONS.md` PO-5 requires public
`ordered` introspection to use the same grouped-query sentinel because
`Query.group_by` documents `None` as the only "no group by" state. The edit
changes the default-ordering branch from `not self.query.group_by` to
`self.query.group_by is None`.

Did not edit tests or run verification commands.

Reason: `fvk/FINDINGS.md` F3 and `fvk/PROOF_OBLIGATIONS.md` PO-6 record the
task constraint and the FVK honesty gate: this proof is constructed, not
machine-checked. The intended `kompile`, `kast`, and `kprove` commands are
listed in `fvk/PROOF.md` and `fvk/ITERATION_GUIDANCE.md`, but they were not
executed here.
