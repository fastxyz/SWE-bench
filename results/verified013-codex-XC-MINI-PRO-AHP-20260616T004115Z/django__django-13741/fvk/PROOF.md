# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Model

The mini semantics keeps exactly the state needed for the issue:

- `defaultRPHF(none)` models `ReadOnlyPasswordHashField()` and rewrites to
  `field(true)`.
- `defaultRPHF(some(B))` models an explicit caller-provided disabled kwarg and
  rewrites to `field(B)`.
- `cleanPassword(field(true), SUB, INIT)` models `BaseForm._clean_fields()` for
  disabled fields and rewrites to `INIT`.
- `cleanPassword(field(false), SUB, INIT)` models the non-disabled branch and
  rewrites to `SUB`.

This abstraction distinguishes the passing and failing cases for the exact
property under audit:

- Failing pre-fix case: default field is `field(false)`, so cleaning can produce
  `SUB`.
- Passing fixed case: default field is `field(true)`, so cleaning produces
  `INIT`.

## Claim C1

Start: `<k> disabledOf(defaultRPHF(none)) </k>`

Step 1: apply the constructor default rule:
`defaultRPHF(none) => field(true)`.

Step 2: apply disabled projection:
`disabledOf(field(true)) => true`.

Result: `<k> true </k>`.

This proves PO1 under the mini semantics.

## Claim C2

Start: `<k> cleanPassword(defaultRPHF(none), SUB, INIT) </k>`

Step 1: strict evaluation of the field argument reduces
`defaultRPHF(none) => field(true)`.

Step 2: apply the disabled cleaning rule:
`cleanPassword(field(true), SUB, INIT) => INIT`.

Result: `<k> INIT </k>`.

Because `SUB` and `INIT` are symbolic values, the result holds for all submitted
and initial password values in the modeled domain. This proves PO2 and PO3.

## Claim C3

Start: `<k> disabledOf(defaultRPHF(some(false))) </k>`

Step 1: apply the explicit-kwarg constructor rule:
`defaultRPHF(some(false)) => field(false)`.

Step 2: apply disabled projection:
`disabledOf(field(false)) => false`.

Result: `<k> false </k>`.

This proves the first half of PO4.

## Claim C4

Start: `<k> cleanPassword(defaultRPHF(some(false)), SUB, INIT) </k>`

Step 1: strict evaluation of the field argument reduces
`defaultRPHF(some(false)) => field(false)`.

Step 2: apply the non-disabled cleaning rule:
`cleanPassword(field(false), SUB, INIT) => SUB`.

Result: `<k> SUB </k>`.

This proves the second half of PO4.

## Adequacy Gate

The English formal spec in `fvk/SPEC.md` matches the public intent:

- The issue asks for the disabled prop to be true by default; C1 states that.
- The issue's quoted disabled-field behavior requires initial data to win over
  tampered submitted data; C2 states that for all values.
- The issue says `clean_password()` should no longer be necessary for custom
  forms; C1 plus C2 states exactly that.
- The phrase "by default" does not require removing explicit caller control; C3
  and C4 preserve that compatibility.

No claim depends on hidden tests, evaluator output, or the current implementation
as its own oracle. The implementation supplies the transition rules being
checked, while the expected behavior comes from public intent.

## Residual Risk

The result is partial correctness over the modeled slice. There are no loops in
the slice, so no termination argument is needed.

The trusted base is the adequacy of the mini semantics, the reachability proof
rules, and later K machine checking. The proof has not been machine-checked
because this task forbids running K tooling.

Existing tests should not be removed. If the K commands later return `#Top`, a
unit test asserting the same in-domain field-level behavior would be logically
subsumed by C1/C2, but admin integration and rendering tests should remain
because this proof does not cover those layers.

## Reproduction Commands

Commands to run in an environment with K installed, not executed here:

```sh
cd fvk
kompile mini-django-forms.k --backend haskell
kast --backend haskell readonly-password-hash-field-spec.k
kprove readonly-password-hash-field-spec.k
```

Expected machine-check result: `#Top`.
