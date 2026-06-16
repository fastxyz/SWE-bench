# FVK Notes

The FVK audit kept V1 unchanged. The decision traces to F-001 and proof
obligations PO-1 through PO-6: V1 exposes `transform_max_iter`, stores it on the
sparse-coding mixin, passes it into `sparse_encode`, and forwards it to
`LassoLars(max_iter=...)` while preserving the existing `Lasso(max_iter=...)`
path.

I kept the parameter name `transform_max_iter` rather than adding a bare
`max_iter` because F-002 and PO-8 resolve that API ambiguity: the existing
public transform controls use the `transform_` prefix, and
`DictionaryLearning.max_iter` already names the fit-loop iteration limit.

I did not add generic `algorithm_kwargs` because F-003 and PO-7 classify that
as broader than the public hint requires. The issue-specific obligation is the
missing lasso-family `max_iter` forwarding, and V1 discharges it directly.

I made no source edits during the FVK pass. F-004 and PO-8 found no public
compatibility blocker, and F-005 records that tests, Python, and K tooling were
not run because this task forbids execution. The constructed proof and commands
are recorded under `fvk/`, but they remain not machine-checked.
