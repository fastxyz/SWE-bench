# FVK Findings

Status: findings are derived from public intent, source inspection, and the
constructed proof obligations. No tests or code were executed.

## F-001: Resolved conditional-child deconstruction crash

Input: `Q(Exists(queryset)).deconstruct()`.

Pre-V1 observed behavior: the single-child branch treated `Exists(...)` as a
lookup pair and attempted `child[0]`, causing `TypeError: 'Exists' object is not
subscriptable`.

Expected behavior: `Exists(...)` is a conditional expression child, so
`deconstruct()` must preserve it in positional `args` and avoid lookup-pair
indexing.

Status: resolved by PO-2. The V1 guard checks `getattr(child, 'conditional',
False) is False` before entering the kwargs branch, so conditional children use
the positional branch.

## F-002: Backwards-compatible single-lookup format is intentionally preserved

Input: `Q(x=1).deconstruct()`.

Observed V1 behavior: returns `('django.db.models.Q', (), {'x': 1})`.

Expected behavior: preserve this format. It appears in the issue statement and
is asserted by public tests.

Status: confirmed by PO-1. This finding justifies not removing the single-child
special case entirely.

## F-003: Nested `Q` positional behavior is preserved

Input: `Q(Q(x=1)).deconstruct()`.

Observed V1 behavior: nested `Q` children have `conditional=True`, so the
positional branch returns `(Q(x=1),)`.

Expected behavior: public tests assert nested `Q` children deconstruct through
positional `args`.

Status: confirmed by PO-3.

## F-004: Arbitrary non-conditional non-lookup children remain unsupported

Input: `Q(False).deconstruct()`.

Observed V1 behavior by branch inspection: `False` has no `conditional` marker,
so it still enters the lookup-pair branch and would be indexed.

Expected behavior for this task: no production change required. The issue
discussion mentions this as a fragility of the old special case, but the public
hint says handling conditional expressions is enough and there is no need to
change the current deconstruction format.

Status: accepted scope boundary, tied to PO-6. This should not justify a broader
patch unless a future public requirement makes arbitrary single-child inputs
part of the supported API.

## F-005: Proof is constructed, not machine-checked

Input: all proof obligations in `fvk/PROOF_OBLIGATIONS.md`.

Observed process: no `kompile`, `kprove`, Python, or test commands were run.

Expected process: the benchmark forbids execution; FVK commands are written as
artifacts only.

Status: honesty caveat. The proof is suitable for a source audit but does not
license test removal.

