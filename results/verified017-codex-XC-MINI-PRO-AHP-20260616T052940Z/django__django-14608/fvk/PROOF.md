# Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove`
commands were run.

## Claims proved in the constructed model

The K claims in `fvk/formset-nonform-spec.k` state:

- C1: unbound formset `non_form_errors()` returns `errorList(noErrors, nonform)`;
- C2: clean bound formset `non_form_errors()` returns
  `errorList(noErrors, nonform)`;
- C3: management-form error path returns
  `errorList(managementErrors, nonform)`;
- C4: formset validation-error path returns
  `errorList(validationErrors, nonform)`;
- C5: the model distinguishes pre-fix `noExtra` rendering from fixed
  `nonform` rendering.

## Symbolic proof sketch

The model has two operational rules relevant to C1-C4:

1. `nonFormErrors(P)` rewrites to `fullClean(P) ~> getNonFormErrors`.
2. `fullClean(P)` stores `errorList(errorsFor(P), nonform)` in the
   `<nonFormErrors>` cell.
3. `getNonFormErrors` returns the stored `ErrorList`.

For each concrete path `P` in `{unbound, clean, management, validation}`,
symbolic execution applies rule 1, then rule 2, then rule 3. The
`errorsFor(P)` simplification gives:

- `errorsFor(unbound) => noErrors`,
- `errorsFor(clean) => noErrors`,
- `errorsFor(management) => managementErrors`,
- `errorsFor(validation) => validationErrors`.

The final state therefore matches the postcondition of C1-C4 exactly, with
the same error contents and `ExtraClass == nonform`.

C5 uses the `classOf()` function rules:

- `classOf(errorList(_, noExtra)) => errorlist`,
- `classOf(errorList(_, nonform)) => errorlistNonform`.

Thus the pre-fix construction and V1 construction map to different rendered
classes. This discharges the non-vacuity/discriminator obligation.

## Mapping to source

PO-1 maps to the source line in `BaseFormSet.full_clean()` that initializes
`self._non_form_errors`.

PO-2 maps to the `except ValidationError as e` branch that replaces
`self._non_form_errors`.

The V1 source satisfies both mappings by passing `error_class='nonform'` to
`self.error_class` at both construction sites.

## Adequacy and compatibility

The adequacy audit in `fvk/SPEC_AUDIT.md` marks each claim as passing against
the intent-only spec. The compatibility audit finds no public consumer shape
that requires a V2 code change. The one conflicting public test is marked as
suspect legacy evidence in F2.

## Residual risk

This is a property-complete mini-model, not a full Python/Django proof. It
proves the CSS-class construction obligation over the relevant finite outcome
paths, assuming the source-to-model mapping in PO-1 and PO-2. It does not prove
termination or all Django validation behavior.

## Machine-check commands to run later

These commands are recorded for a future environment with K installed. They
were not executed in this benchmark session.

```sh
cd fvk
kompile mini-django-errorlist.k --backend haskell
kast --backend haskell formset-nonform-spec.k
kprove formset-nonform-spec.k
```

Expected result after any needed syntax adjustments for a concrete K
installation: `#Top` for all claims.

## Test-redundancy recommendation

No tests should be removed in this benchmark task. If the K artifacts are
machine-checked later, tests asserting only the in-domain CSS class of
`formset.non_form_errors()` would be subsumed by C1-C4, but integration tests,
admin rendering tests, message-content tests, and custom `ErrorList` tests
should remain.
