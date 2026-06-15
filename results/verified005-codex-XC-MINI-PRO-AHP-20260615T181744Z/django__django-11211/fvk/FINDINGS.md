# FVK Findings

Status: constructed, not machine-checked.

## F-001: V1 addresses the reported UUID GFK prefetch mismatch

Input: source object id `Str(S)` where `validUuid(S)`, target object primary key `UUID(canonUuid(S))`, target class `Foo`.

Observed before V1 by source inspection: `GenericForeignKey.gfk_key()` used `UUIDField.get_prep_value(Str(S))`, but `UUIDField` inherited `Field.get_prep_value()` and returned `Str(S)` unchanged. `prefetch_one_level()` keyed related objects by `(UUID(canonUuid(S)), Foo)`, so the source key `(Str(S), Foo)` missed and the single relation was cached as `None`.

Expected from I-001 and I-002: source and related keys must both be `(UUID(canonUuid(S)), Foo)`, so `bar.foo` is populated.

V1 status: discharged by PO-001, PO-002, and PO-003.

## F-002: Public hint conflicts with checkout docs and implementation

Input: the public hint says `GenericForeignKey` does not support `prefetch_related()`.

Observed in allowed source: `repo/docs/ref/models/querysets.txt` documents GFK prefetch support, and `repo/django/contrib/contenttypes/fields.py` implements `GenericForeignKey.get_prefetch_queryset()`. Public tests also exercise GFK prefetch.

Expected: treat the hint as stale or overbroad for this checkout. Preserve the documented limitation on direct GFK `filter()`/`exclude()`, but fix the documented prefetch path.

V1 status: discharged by PO-006.

## F-003: Field-level normalization is the minimal adequate repair

Input: `UUIDField.get_prep_value(Str(S))` for a valid textual UUID.

Observed before V1: inherited base preparation did not call `UUIDField.to_python()`.

Expected: UUIDField should prepare values into the same Python type used by loaded UUIDField values, i.e. `uuid.UUID`.

V1 status: discharged by PO-001 and PO-005. No additional source change is justified by this FVK pass.

## F-004: Proof is constructed only

Input: FVK method requires K artifacts and `kompile`/`kprove` commands.

Observed: the task forbids running tests, Python, or K tooling.

Expected: emit artifacts and exact commands, label the proof constructed and not machine-checked, and avoid test removal.

V1 status: residual process limitation, not a code bug. Covered by PO-008.

## F-005: Public test gap remains outside this task's editable surface

Input: a regression scenario with `GenericForeignKey` to a UUID primary key and a `CharField` object id.

Observed: public tests cover GFK prefetch, non-integer object id storage, and UUID prefetch in other relation types, but the exact UUID-GFK-forward-prefetch case is not present in the visible tests.

Expected: a future public regression test should assert that `prefetch_related('foo')` populates the GFK cache for this case. The current task forbids modifying test files.

V1 status: test gap only; no production-code change required.
