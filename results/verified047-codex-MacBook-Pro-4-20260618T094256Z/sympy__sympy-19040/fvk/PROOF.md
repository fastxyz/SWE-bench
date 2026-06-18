# Proof

Status: constructed (escalation-bounded), not machine-checked.

No K tooling was run. The commands below are the reproduction commands that
would need to return `#Top` before this package could be called
machine-checked.

## Commands

```sh
cd fvk
kompile mini-factor.k --backend haskell --main-module MINI-FACTOR --syntax-module MINI-FACTOR-SYNTAX
kast dmp-ext-factor-spec.k --definition mini-factor-kompiled --module DMP-EXT-FACTOR-SPEC --sort Claim
kprove dmp-ext-factor-spec.k --definition mini-factor-kompiled --spec-module DMP-EXT-FACTOR-SPEC
kprove dmp-ext-factor-obligations.k --definition mini-factor-kompiled --spec-module DMP-EXT-FACTOR-OBLIGATIONS
```

Expected result if all obligations are supplied with a sufficient bag/algebraic
theory: `#Top`. Current status remains constructed, not machine-checked.

## Constructed proof sketch

### Issue claim

Start:

```text
dmpExtFactor(poly(1, 1, {YMINUS1}, {XMINUS1}))
```

The V1 semantic rule rewrites this to trial division over:

```text
append(contentCandidates({YMINUS1}), primitiveCandidates({XMINUS1}))
```

The candidate functions reduce to:

```text
append({YMINUS1}, {XMINUS1}) = {YMINUS1, XMINUS1}
```

Restricting the original factor bag `{YMINUS1, XMINUS1}` to those candidates
preserves both factors. The result is:

```text
factored(1, {YMINUS1, XMINUS1})
```

This discharges the reported bug shape in the mini semantics.

### Legacy diagnostic

The legacy semantic rule uses only:

```text
primitiveCandidates({XMINUS1}) = {XMINUS1}
```

Restricting `{YMINUS1, XMINUS1}` to `{XMINUS1}` drops `YMINUS1`, yielding:

```text
factored(1, {XMINUS1})
```

This localizes the reported symptom to missing content candidates.

### Frame scenarios

- No content: `contentCandidates(.FBag)` is empty and `CC = 1`, so V1 reduces
  to the primitive/norm candidate path.
- Content only: `primitiveCandidates(.FBag)` is empty, so V1 returns content
  candidates through the same trial-division multiplicity mechanism.
- Coefficient: V1 returns `LC * CC`, matching reconstruction of the original
  product.

### General claim

The general claim follows from the explicit obligations in
`dmp-ext-factor-obligations.k`:

- `BAG-COVERAGE`: candidate enumeration covers every content and primitive
  factor.
- `TRIAL-MULTIPLICITY`: trial division returns original multiplicities for
  present candidates.
- `PRIMITIVE-SPLIT`: `dmp_primitive` preserves product decomposition.
- `NORM-CANDIDATES`: the existing square-free norm path remains complete for
  primitive factors.

These are not hidden `[trusted]` claims. They are visible escalation boundaries.

## Repair decision

The proof package found the pre-V1 bug mechanism and did not produce a concrete
V1 counterexample or unmet obligation that V1 demonstrably fails. Under the
revision discipline, V1 stands unchanged.

## Test recommendation

Do not remove tests based on this constructed proof. Test removal would require
running the emitted `kprove` commands and obtaining `#Top`.
