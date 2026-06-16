# FVK Proof Obligations: django__django-15277

Status: constructed, not machine-checked.

## PO1: The issue path reaches unbounded `CharField`

Statement:

For a string value, `Value._resolve_output_field()` must call
`fields.CharField()` without a `max_length` argument.

Provenance:

E1 and E7 in `fvk/SPEC.md`.

Discharge:

The source branch for `isinstance(self.value, str)` returns
`fields.CharField()`. Because `Field.__init__()` defaults `max_length` to
`None`, this reaches the unbounded constructor case.

Status: discharged by source inspection and represented by
`VALUE-STRING-OUTPUT-FIELD`.

## PO2: Unbounded construction does not append a max-length validator

Statement:

For all validator sequences `VS`, constructing `CharField(max_length=None)`
must leave the automatic max-length validator absent.

Formal shape:

```k
claim
  <k> charField(none, VS:Validators) => field(none, VS) </k>
  [all-path]
```

Provenance:

E2, E3, and E5 in `fvk/SPEC.md`.

Discharge:

V1 executes the append only in the `self.max_length is not None` branch. When
`self.max_length is None`, the branch is skipped and the validator sequence is
unchanged.

Status: discharged by `UNBOUNDED-CHARFIELD-NO-MAX-VALIDATOR`.

## PO3: Bounded construction still appends the matching validator

Statement:

For every non-`None` max length `L`, construction must append an automatic
`MaxLengthValidator(L)`.

Formal shape:

```k
claim
  <k> charField(some(L:Limit), VS:Validators)
      => field(some(L), VS ; MaxLengthValidator(some(L))) </k>
  [all-path]
```

Provenance:

E3, E4, and E8 in `fvk/SPEC.md`.

Discharge:

For `self.max_length is not None`, V1 follows the existing append path and
constructs `validators.MaxLengthValidator(self.max_length)`.

Status: discharged by `BOUNDED-CHARFIELD-KEEPS-MAX-VALIDATOR`.

## PO4: Existing default and user validators are preserved

Statement:

The change must not remove, reorder, or replace validators already supplied by
`Field.default_validators` or the `validators=` argument.

Provenance:

E3 and source evidence from `Field.validators` in `fvk/SPEC.md`.

Discharge:

V1 only makes the automatic max-length append conditional. It does not alter
`Field.__init__()`, `_validators`, `default_validators`, or the
`validators` cached property. In the unbounded case, existing validators remain
the entire sequence. In the bounded case, the previous automatic append path is
retained.

Status: discharged.

## PO5: Constructor/API compatibility is preserved

Statement:

The public constructor signature and downstream behavior outside max-length
validator creation must remain unchanged.

Provenance:

E4, E6, and public compatibility audit in `fvk/SPEC.md`.

Discharge:

V1 changes one statement to a guarded two-line statement inside the existing
method body. It does not change parameters, return shape, `db_collation`,
deconstruction, form-field creation, or database type behavior.

Status: discharged.

## PO6: Concrete model fields without `max_length` still fail system checks

Statement:

For concrete model `CharField(max_length=None)`, the system check must continue
to report `fields.E120`.

Provenance:

E6 in `fvk/SPEC.md`.

Discharge:

`CharField._check_max_length_attribute()` is unchanged and still returns
`fields.E120` when `self.max_length is None`.

Status: discharged by frame inspection.

## PO7: Proof honesty and execution boundary

Statement:

The FVK proof must be labeled constructed, not machine-checked, because this
session must not run tests, Python, `kompile`, or `kprove`.

Provenance:

User task restrictions and FVK verify.md honesty gate.

Discharge:

All artifacts record exact commands to run later and state that they were not
executed here.

Status: discharged.
