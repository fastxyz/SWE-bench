# FVK Proof: django__django-15277

Status: constructed, not machine-checked.

This proof is a partial-correctness argument over the validator-state
observable described in `fvk/SPEC.md`. There are no loops or recursive calls in
the audited code path, so no circularity claim is needed. The proof uses
symbolic case analysis on whether `max_length` is `None`.

## Claims

The formal claims are emitted in `fvk/charfield-spec.k`:

1. `UNBOUNDED-CHARFIELD-NO-MAX-VALIDATOR`
2. `BOUNDED-CHARFIELD-KEEPS-MAX-VALIDATOR`
3. `VALUE-STRING-OUTPUT-FIELD`

The system-check frame condition is discharged by source inspection because
`_check_max_length_attribute()` is unchanged.

## Constructed Proof Sketch

Initial state:

`CharField.__init__()` is entered after `Field.__init__()` has assigned
`self.max_length` and initialized the validator sources. The relevant symbolic
state is `(max_length, validators)`.

Case 1: `max_length is None`.

V1 evaluates the guard `self.max_length is not None` to false. The append call
is not executed. Therefore the automatic max-length validator is absent and the
validator sequence remains exactly the default/user sequence `VS`. This
discharges PO2 and Finding F1.

Case 2: `max_length is not None`.

V1 evaluates the guard to true. The method executes the same append operation
used before V1:
`self.validators.append(validators.MaxLengthValidator(self.max_length))`.
Therefore the constructed automatic validator carries the same non-`None`
limit value. This discharges PO3 and Finding F2.

String `Value` path:

`Value._resolve_output_field()` checks `isinstance(self.value, str)` before the
numeric and date/time cases and returns `fields.CharField()`. This is the
unbounded constructor case because `Field.__init__()` defaults `max_length` to
`None`. By Case 1, the resulting output field has no automatic max-length
validator. This discharges PO1 and PO2 together.

Frame conditions:

`CharField.__init__()` still calls `super().__init__(*args, **kwargs)` and still
assigns `self.db_collation = db_collation`. No public signature or call shape is
changed. `_check_max_length_attribute()` is unchanged and still reports
`fields.E120` when `self.max_length is None`. This discharges PO4, PO5, and
PO6.

## Verification Conditions

VC1: `None` branch preserves validators.

Required implication:

`max_length = None -> validators_after = VS`

Reason:

The guarded append is skipped. No other statement in the V1 diff mutates
validators.

Status: discharged.

VC2: non-`None` branch appends the matching limit.

Required implication:

`max_length = L and L != None -> validators_after includes MaxLengthValidator(L)`

Reason:

The true branch executes the unchanged append expression with
`self.max_length` as the argument.

Status: discharged.

VC3: string `Value` resolution reaches VC1.

Required implication:

`isinstance(value, str) -> output_field = CharField(max_length=None)`

Reason:

The source branch returns `fields.CharField()` without a `max_length` argument,
and `Field.__init__()` defaults that parameter to `None`.

Status: discharged.

VC4: model-field validity remains a system-check concern.

Required implication:

`max_length = None` on a concrete model `CharField` still yields `fields.E120`
from checks.

Reason:

The check method was not edited.

Status: discharged by frame inspection.

## Machine-Check Commands

These commands are exact reproduction commands for a later environment with K
installed. They were not run in this session.

```sh
kompile fvk/mini-python-charfield.k --backend haskell
kast --backend haskell fvk/charfield-spec.k
kprove fvk/charfield-spec.k
```

Expected machine-check result after a real run: `#Top` for all claims. This is
an expectation from the constructed proof, not an observed result.

## Test Guidance

No tests were run or modified. Because the proof is constructed but not
machine-checked, no test removal is recommended here. A later test suite should
keep integration and system-check coverage. A focused regression test, if the
fixed suite contains one, would assert that `Value('test')._resolve_output_field()`
does not include a `MaxLengthValidator` with `limit_value is None`.

## Residual Risk

The trusted base is the adequacy of the mini semantics for this validator
observable, the source inspection of unmodeled Django framework behavior, and a
future K toolchain run. The proof does not address performance timing beyond
removing the unnecessary validator construction on the unbounded path.
