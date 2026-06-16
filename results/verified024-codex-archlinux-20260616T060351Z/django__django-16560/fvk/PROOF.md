# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or Django tests were run.

## What is proved

For the abstract validation model in `mini-constraint-validation.k`, the claims
in `constraint-validation-spec.k` prove partial correctness of the source-level
obligations in `PROOF_OBLIGATIONS.md`:

- a supplied `violation_error_code` is stored;
- omitted code remains `NoCode`;
- deconstruction includes custom code and omits absent code;
- violated constraint-message branches raise `ValidationError(stored_code)`;
- field-only `UniqueConstraint` without condition reaches the legacy unique
  error branch;
- non-violations return successfully.

There are no loops or recursive functions in the modeled fragment, so no loop
circularity or termination measure is required.

## Source-to-model correspondence

The model's `Code` cell corresponds to `BaseConstraint.violation_error_code`.
The model's `kwargs` map corresponds to the third element of
`BaseConstraint.deconstruct()`. The model's `ValidationError(C)` outcome
corresponds to calling Django's `ValidationError(..., code=C)` in a validation
branch that uses `get_violation_error_message()`.

The model abstracts the violation predicate as a boolean because query
construction and database lookup are not changed by this issue. This abstraction
is property-complete for the defect: it distinguishes the failing pre-fix
observable `ValidationError(NoCode)` from the intended
`ValidationError(Code("custom_code"))`.

## Proof sketch

P-1. Constructor storage.

The `init(Code(S))` semantic rule rewrites `<code> NoCode` to
`<code> Code(S)`. This corresponds to `BaseConstraint.__init__` assigning
`self.violation_error_code = violation_error_code` when the argument is not
`None`.

P-2. Default preservation.

The `init(NoCode)` semantic rule leaves `<code> NoCode` unchanged. This matches
the source rule that omits assignment when the argument is `None`, leaving the
class default `None`.

P-3. Deconstruction.

The `deconstruct` rule with `Code(S)` updates the kwargs map at
`"violation_error_code"` to `S`; the `NoCode` rule leaves kwargs unchanged. This
matches `BaseConstraint.deconstruct()` adding the kwarg only for non-`None`
stored codes.

P-4. Validation errors.

The `validate(Check, true)`, `validate(UniqueExpr, true)`,
`validate(UniqueCond, true)`, and `validate(Exclusion, true)` rules all rewrite
the outcome to `ValidationError(C)` while preserving the stored code `C`. These
rules correspond exactly to the updated source raises that pass
`code=self.violation_error_code`.

P-5. Legacy unique branch.

The `validate(UniqueFieldsLegacy, true)` rule rewrites to `LegacyUniqueError`
instead of `ValidationError(C)`. This is not a proof gap: it encodes the public
documentation statement that `violation_error_message` is not used for
field-only `UniqueConstraint` without condition.

P-6. Non-violation frame.

The `validate(K, false)` rule rewrites to `Ok`, preserving the old behavior that
adding a code parameter does not make validation fail when no violation is
detected.

## Machine-check commands not run

From the FVK artifact directory, a human with K installed could run:

```sh
cd fvk
kompile mini-constraint-validation.k --backend haskell
kast --backend haskell constraint-validation-spec.k
kprove constraint-validation-spec.k
```

Expected result after any syntax adjustments required by a local K version:
`kprove` returns `#Top` for all claims. This expectation is constructed from the
one-step rewrite rules above; it has not been machine-checked in this session.

## Residual risk

The proof is over a deliberately small abstraction, not the full Python/Django
runtime. It verifies the error-code observable affected by the patch and does
not prove database query correctness, expression semantics, SQL generation,
termination, or integration behavior. Test removal is not recommended without a
real machine check and project test run, both of which are forbidden here.
