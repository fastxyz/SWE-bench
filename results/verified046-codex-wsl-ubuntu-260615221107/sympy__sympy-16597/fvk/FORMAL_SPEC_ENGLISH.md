# Formal Spec In English

Status: constructed, not machine-checked.

The K artifacts are `mini-assumptions.k` and `assumptions-spec.k`.

Claim A, `close({even})`: starting from the old-assumption fact `even=True`,
the closure process reaches a fixed point containing `finite=True`.

Claim B, `close({odd})`: starting from the old-assumption fact `odd=True`, the
closure process reaches a fixed point containing `finite=True`.

Claim C, `close({integer})`: starting from `integer=True`, the closure process
reaches a fixed point containing `finite=True`.

Claim D, `close({rational})`: starting from `rational=True`, the closure process
reaches a fixed point containing `finite=True`.

Claim E, `close({real})`: starting only from old-assumption `real=True`, the
closure process does not add `finite=True`. This is a frame condition for the
chosen scope, not a claim that this broader behavior is mathematically ideal.

Claim F, `close({})`: starting from no relevant numeric-set facts, the closure
process does not add `finite=True`; an unconstrained symbol remains unknown.

The mini semantics includes only the rules needed to distinguish the defect:
`even -> integer`, `odd -> integer`, `integer -> rational`, V1
`rational -> finite`, and the existing `rational -> real` frame edge.
