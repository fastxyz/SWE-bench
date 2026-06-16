# Spec Audit

| Formal item | Intent item | Verdict | Rationale |
| --- | --- | --- | --- |
| `LEN`: `pipelineLen(pipeline(N)) => N` for `N >= 0` | Intent items 1 and 2 | PASS | It states that `len(pipe)` is defined and returns the number of steps. |
| `FULL-SLICE-AFTER-LEN`: full-prefix slice after length returns `pipeline(N)` | Intent item 3 | PASS | It captures the reported `pipe[:len(pipe)]` path and requires it to preserve all steps. |
| `N >= 0` cardinality side condition | Domain/default assumptions | PASS | Sequence lengths are non-negative. This is not candidate-derived. |
| No `__iter__` or broader sequence protocol | Intent item 4 | PASS | The formal spec and source patch add only `__len__`. |
| Existing indexing behavior framed unchanged | Intent item 5 | PASS | The source patch does not change `__getitem__`; the formal model uses it only as existing slice semantics. |
| Valid-pipeline truthiness compatibility | Domain/default assumptions | PASS | Valid constructed pipelines have at least one step, so `bool(pipe)` remains true for valid objects after `__len__`. |

No formal-English item is candidate-derived without public evidence, and no
required behavior is marked fail or ambiguous.
