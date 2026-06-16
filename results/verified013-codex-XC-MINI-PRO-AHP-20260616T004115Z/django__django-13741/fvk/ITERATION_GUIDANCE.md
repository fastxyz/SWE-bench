# Iteration Guidance

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Code Decision

V1's runtime source fix stands: `ReadOnlyPasswordHashField.__init__()` defaults
`disabled` to true. Findings F1 and F2 plus proof obligations PO1-PO3 justify
that conclusion.

The audit made one V2 change outside runtime source: the custom-user docs
example no longer includes the obsolete `clean_password()` method. Finding F3
and proof obligation PO6 justify that edit.

## Rejected Change

Do not remove `UserChangeForm.clean_password()` in this pass. Finding F4 and
PO5 show that the method is redundant for correctness but compatible with the
new field-level behavior. Removing it would be an avoidable public-method
compatibility change.

## Suggested Tests For A Normal Development Environment

Do not edit tests in this benchmark task. In a normal Django contribution, add
or keep tests covering:

- `ReadOnlyPasswordHashField().disabled is True`.
- A custom model form with `ReadOnlyPasswordHashField()` and no
  `clean_password()` ignores a submitted password value and keeps the initial
  hash.
- `ReadOnlyPasswordHashField(disabled=False)` remains an explicit opt-out if
  Django wants to preserve that compatibility frame.

## Conditional Test Redundancy

No tests should be removed from this task. After the K claims are
machine-checked with `kprove` returning `#Top`, narrow unit tests that only
repeat C1/C2 would be candidates for redundancy. Integration, admin rendering,
docs, and model-save tests should remain because the mini semantics does not
cover those layers.

## Commands Not Run

The following commands are recorded for later use only:

```sh
cd fvk
kompile mini-django-forms.k --backend haskell
kast --backend haskell readonly-password-hash-field-spec.k
kprove readonly-password-hash-field-spec.k
```
