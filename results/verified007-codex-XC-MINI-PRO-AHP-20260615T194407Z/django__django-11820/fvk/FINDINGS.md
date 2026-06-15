# FVK FINDINGS

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and the proof obligations; no tests or code were run.

## F1: Original Regression, Fixed By V2

Input: a model whose `Meta.ordering` contains `option__pk`, where `option` is a
valid relation to a model with primary key field `id`.

Observed before the repair described by this audit: `_check_ordering()` attempted
to resolve a literal field named `pk` on the related model and emitted
`models.E015`.

Expected: `option__pk` is valid because `pk` aliases the related model's concrete
primary key while resolving model field paths.

Classification: code bug. Status: fixed by PO-1 and the current source change
that maps `pk` to `_cls._meta.pk.name` while still in relation/model context.

## F2: V1 Over-Accepted `pk` After Non-Relational Fields

Input: a model with a concrete non-relational field `test` and
`Meta.ordering = ('test__pk',)`, assuming `test` has no registered transform
named `pk`.

Observed under V1: the checker would see `test` as a scalar field, then
unconditionally rewrite the next component `pk` to the model's primary-key field
name and accept the path.

Expected: after `test` is resolved as a non-relational field, later components
are transforms on `test`, not fields on the model. Without a `pk` transform,
`test__pk` must raise `models.E015`.

Classification: code bug introduced by V1. Status: fixed by PO-3 and the V2
guard that forces suffixes after scalar fields through `get_transform()`.

## F3: V2 Also Corrects A Broader False Negative For Scalar Suffixes

Input: a model with concrete non-relational field `test`, another model field
`id`, and `Meta.ordering = ('test__id',)`, assuming `test` has no registered
transform named `id`.

Observed in the pre-existing traversal shape: after resolving `test`, the loop
could still resolve `id` as a model field and accept the path.

Expected: `id` after `test` is a transform/lookup component, not another model
field path component. Without an `id` transform on `test`, the checker should
raise `models.E015`.

Classification: code bug on the same path-localization axis as F2. Status:
fixed by the same V2 scalar-field guard. This is justified because it is the
general rule needed to make the `pk` fix sound, not an unrelated refactor.

## F4: No Machine Check Or Test Execution Performed

The proof is constructed only. `kompile`, `kast`, `kprove`, Python, and Django
tests were not run because the task forbids execution. This is not a code
finding, but test deletion and proof confidence remain conditioned on a future
machine check.
