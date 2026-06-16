# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F1: Pre-V1 predicate was too broad

Input: a multi-table child model whose promoted parent-link primary key has
`pk.auto_created=true`, `pk is _meta.auto_field=false`, and no default-auto-field
override.

Observed before V1: `_check_default_pk()` checked only `pk.auto_created` plus the
override flags, so it emitted `models.W042`.

Expected from public intent: no `models.W042`, because the primary key type was
defined on the ancestor and the child inherits it through the parent link.

Classification: code bug fixed by V1.

Related proof obligations: PO1, PO4.

## F2: V1 uses the right discriminator

Input: the same inherited parent-link primary key metadata as F1.

Observed after V1 by source inspection: `_check_default_pk()` also requires
`cls._meta.pk is cls._meta.auto_field`. The parent link is a `OneToOneField`
created for inheritance and is not recorded by `AutoFieldMixin` as
`_meta.auto_field`, so the predicate is false and no W042 is emitted.

Expected from public intent: no `models.W042`.

Classification: confirmed behavior.

Related proof obligations: PO1, PO4, PO5.

## F3: Existing intended warning cases remain covered

Input: a model with an implicit default auto primary key and no project or app
default-auto-field override.

Observed after V1 by source inspection: the implicit default path creates
`pk_class(..., auto_created=True)` and `AutoFieldMixin.contribute_to_class()`
records that field as `_meta.auto_field`, so the V1 predicate remains true.

Expected from public tests and warning semantics: emit `models.W042`.

Classification: preserved intended behavior.

Related proof obligations: PO2, PO4.

## F4: Verification is constructed, not machine-checked

Input: the K artifacts in `fvk/mini-default-pk.k` and `fvk/default-pk-spec.k`.

Observed in this environment: the FVK proof can be constructed and commands can
be written, but K tooling must not be run here.

Expected follow-up: run the emitted `kompile`, `kast`, and `kprove` commands in
an environment where K execution is permitted before treating the proof as
machine-checked.

Classification: proof capability gap, not a source-code bug.

Related proof obligations: PO6.
