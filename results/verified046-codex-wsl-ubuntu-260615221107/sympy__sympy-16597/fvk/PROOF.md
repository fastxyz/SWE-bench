# Constructed Proof

Status: constructed, not machine-checked.

## Commands Not Run

The benchmark forbids running K tooling. These are the commands to run later:

```sh
kompile fvk/mini-assumptions.k --backend haskell
kast --backend haskell fvk/assumptions-spec.k
kprove fvk/assumptions-spec.k
```

Expected machine-check result after successful parsing and proof: `#Top`.

## Proof Sketch

The mini semantics rewrites `close(FS)` by adding any missing fact forced by the
modeled old-assumption implications. It reaches `done(FS)` only when no modeled
edge can add a new fact.

For `rational`:

1. Initial set is `{rational}`.
2. The V1 rule `rational -> finite` fires, adding `finite`.
3. The existing frame rule `rational -> real` may also fire.
4. At fixed point, the set contains `finite`.

This discharges PO-1 and claim D.

For `integer`:

1. Initial set is `{integer}`.
2. Existing rule `integer -> rational` fires.
3. The rational proof above applies.
4. At fixed point, the set contains `finite`.

This discharges PO-3 and claim C.

For `even`:

1. Initial set is `{even}`.
2. Existing parity rule projection `even -> integer` fires.
3. The integer proof above applies.
4. At fixed point, the set contains `finite`.

This discharges PO-2 and claim A.

For `odd`:

1. Initial set is `{odd}`.
2. Existing parity rule projection `odd -> integer` fires.
3. The integer proof above applies.
4. At fixed point, the set contains `finite`.

This discharges PO-2 and claim B.

For `real`:

1. Initial set is `{real}`.
2. No modeled edge has `real` as an antecedent for `finite`.
3. The fixed point therefore lacks `finite`.

This discharges PO-5 and claim E.

For the empty set:

1. Initial set is `{}`.
2. No modeled edge can fire.
3. The fixed point lacks `finite`.

This discharges PO-6 and claim F.

## Adequacy Gate

`FORMAL_SPEC_ENGLISH.md` paraphrases each K claim. `SPEC_AUDIT.md` compares the
claims with `INTENT_SPEC.md` and marks all obligations pass. No claim depends
only on the current implementation's output; implementation facts are used only
to model the existing graph edges.

## Residual Risk

The proof is partial and constructed only. It does not prove K parser acceptance
or machine discharge because `kompile`, `kast`, and `kprove` were not run.

The mini semantics abstracts away unrelated assumptions. This is adequate for
the defect because it preserves the discriminator: without the V1 edge
`rational -> finite`, the `rational`, `integer`, `even`, and `odd` claims fail;
with that edge, they close.

No test-removal recommendation is made. Existing and hidden tests should be kept
until the emitted K commands are machine-checked and conventional tests are run
outside this no-execution benchmark session.
