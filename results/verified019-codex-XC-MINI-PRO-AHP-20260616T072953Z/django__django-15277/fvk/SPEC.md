# FVK Specification: django__django-15277

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 change to
`repo/django/db/models/fields/__init__.py`, specifically
`CharField.__init__()`, and its effect on string expression output fields
created by `Value._resolve_output_field()`.

The observable property under verification is the validator sequence attached
to a `CharField` after construction:

- An unbounded `CharField()` must not receive a
  `MaxLengthValidator(None)`.
- A bounded `CharField(max_length=L)` must keep the existing
  `MaxLengthValidator(L)` behavior for non-`None` limits.
- Existing default/user validators must be preserved.
- Concrete model `CharField` instances without `max_length` must continue to
  be rejected by system checks, not by an invalid runtime validator.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "`Value('test')` ... `return fields.CharField()`" | String values resolve to a bare `CharField()` output field. | Encoded by `VALUE-STRING-OUTPUT-FIELD`. |
| E2 | prompt | "`MaxLengthValidator` ... cannot work and must be demonstrably extraneous" | No max-length validator may be created when the field has no maximum length. | Encoded by `UNBOUNDED-CHARFIELD-NO-MAX-VALIDATOR`. |
| E3 | prompt | "Change the `CharField.__init__` to: `if self.max_length is not None: ...`" | Validator creation is conditional on `max_length is not None`. | Encoded by both constructor claims. |
| E4 | prompt | "same process taken by `BinaryField.__init__` for precedent" | The guard shape is already an accepted Django field pattern. | Compatibility support. |
| E5 | source | `Field.__init__(..., max_length=None, ...)` | Absence of `max_length` is represented as `None`. | Encoded as `none` in the mini semantics. |
| E6 | source | `CharField._check_max_length_attribute()` returns `fields.E120` when `self.max_length is None`. | Model field validity is still enforced by system checks. | Frame condition. |
| E7 | source | `Value._resolve_output_field()` returns `fields.CharField()` for `str`. | The issue path reaches an unbounded `CharField`. | Encoded by `VALUE-STRING-OUTPUT-FIELD`. |
| E8 | source | `BinaryField.__init__()` appends `MaxLengthValidator` only when `self.max_length is not None`. | V1 follows local precedent for optional max lengths. | Compatibility support. |

Quoted pre-fix examples in the issue showing a validator list containing
`MaxLengthValidator(None)` are treated as SUSPECT legacy behavior. They
describe the reported defect, not intended behavior.

## Intent-Only Spec

1. For any construction of `CharField` with `max_length is None`, the automatic
   max-length validator must be absent.
2. For any construction of `CharField` with `max_length is not None`, the
   automatic max-length validator must be present and use exactly that limit.
3. Validators supplied from `Field.default_validators` and the `validators=`
   argument must remain present and in their existing relative order.
4. `Value._resolve_output_field()` for a string must produce an unbounded
   `CharField` that satisfies obligation 1.
5. This fix must not change `CharField.__init__()`'s public signature,
   `db_collation` handling, deconstruction behavior, form-field behavior, or
   system-check behavior.

## Formal Model

The auxiliary formal core is emitted as:

- `fvk/mini-python-charfield.k`
- `fvk/charfield-spec.k`

The mini semantics abstracts Python object construction to the property that
matters for this issue: `max_length` and the validator sequence. It does not
model database backends, descriptors, cached properties, model metaclasses, or
validation execution because none of those can distinguish the passing and
failing states for this bug. The discriminator is preserved:

- Failing pre-fix state: `field(none, VS ; MaxLengthValidator(none))`
- Passing V1 state: `field(none, VS)`

## Formal Claims In Plain English

`UNBOUNDED-CHARFIELD-NO-MAX-VALIDATOR`

For every starting validator sequence `VS`, constructing a `CharField` with
`max_length = None` returns a field with exactly `VS`; no
`MaxLengthValidator(None)` is appended.

`BOUNDED-CHARFIELD-KEEPS-MAX-VALIDATOR`

For every non-`None` limit value `L` and starting validator sequence `VS`,
constructing a `CharField` with `max_length = L` returns a field whose
validators are `VS` followed by `MaxLengthValidator(L)` in the model. This
represents the constructor still appending the automatic validator whenever the
limit is present. Separate Django system checks determine whether `L` is a
valid positive integer for concrete model fields.

`VALUE-STRING-OUTPUT-FIELD`

Resolving a string `Value` output field follows the `fields.CharField()` path
and reaches the unbounded constructor behavior, so the resulting field has no
max-length validator.

`MODEL-CHECK-FRAME`

The system-check rule for concrete model `CharField(max_length=None)` is not
changed. The field object no longer has an invalid runtime validator, but
`_check_max_length_attribute()` still reports `fields.E120`.

## Adequacy Audit

| Formal claim | Intent entries | Result | Notes |
| --- | --- | --- | --- |
| `UNBOUNDED-CHARFIELD-NO-MAX-VALIDATOR` | E2, E3, E5 | Pass | Captures the exact defect: no validator with a `None` limit. |
| `BOUNDED-CHARFIELD-KEEPS-MAX-VALIDATOR` | E3, E4, E8 | Pass | Preserves existing bounded behavior. |
| `VALUE-STRING-OUTPUT-FIELD` | E1, E7 | Pass | Connects the issue reproduction to `CharField.__init__()`. |
| `MODEL-CHECK-FRAME` | E6 | Pass | Confirms V1 does not make model fields without `max_length` valid. |
| Public compatibility frame | E3, E4, E6 | Pass | No public signature, dispatch, or return-shape change. |

No formal-English claim is stronger than the public intent in a way needed to
justify V1. The only implementation-derived facts used are the local route
through `Value._resolve_output_field()` and the shape of `Field.validators`;
both are used to model the audited mechanism, not to define intended behavior.

## Public Compatibility Audit

Changed public symbol: `django.db.models.fields.CharField.__init__`.

Compatibility result: pass.

- Signature remains `(*args, db_collation=None, **kwargs)`.
- `db_collation` assignment remains unchanged.
- `check()`, `_check_max_length_attribute()`, `deconstruct()`, `formfield()`,
  and database type behavior remain unchanged.
- Subclasses that set defaults before `super().__init__()`, including
  `EmailField`, `SlugField`, and `URLField`, still pass non-`None`
  `max_length` values and still receive a max-length validator.
- Subclasses without a default max length, such as `CICharField`, inherit the
  corrected unbounded behavior and still rely on system checks for concrete
  model validity.

## Exact Commands To Machine-Check Later

These commands are recorded for reproducibility only. They were not run.

```sh
kompile fvk/mini-python-charfield.k --backend haskell
kast --backend haskell fvk/charfield-spec.k
kprove fvk/charfield-spec.k
```
