# FINDINGS

Status: constructed, not machine-checked. No tests, Python, or K tooling were
executed.

## F1: Resolved Code Bug - Generated Display Method Overrode Explicit Method

Input/state:

- A model class defines a choices field `foo_bar`.
- The same class body defines `get_foo_bar_display()`.

Observed before V1:

- `Field.contribute_to_class()` unconditionally assigned
  `get_foo_bar_display = partialmethod(cls._get_FIELD_display, field=field)`.
- The explicit method was replaced.

Expected from public intent:

- The explicit model method is an override and remains the method resolved by
  instances.

V1 result:

- Fixed. The generated helper is installed only when the method name is absent
  from `cls.__dict__`.

Relevant proof obligations: PO1, PO2.

## F2: Confirmed - Declaration Order No Longer Decides the Winner

Input/state:

- `get_foo_bar_display()` appears either before or after `foo_bar =
  models.CharField(..., choices=...)` in the class body.

Observed before the ModelBase construction change described by the issue:

- Winner depended on the order in which attributes were contributed.

Expected from public hints:

- "Semantically order shouldn't make a difference."

V1 result:

- Confirmed. `ModelBase.__new__()` passes ordinary methods to `type.__new__()`
  before field contribution, so either class-body order makes the method present
  in `cls.__dict__` when the field contributes.

Relevant proof obligations: PO1, PO2.

## F3: Rejected Alternative - `hasattr()` Is Too Broad

Input/state:

- A child model receives a copied choices field from an abstract base model.
- The abstract base also has an inherited generated display method for the base
  field instance.

Observed for the `hasattr()` alternative:

- `hasattr(child, method_name)` can be true because of the inherited generated
  method.
- The child would skip installing a generated method bound to the copied child
  field.

Expected compatibility frame:

- Abstract base fields are copied into children and contributed as child fields;
  generated display helpers should continue to bind to the contributed field
  when there is no explicit direct override on the child.

V1 result:

- Confirmed. Checking `method_name not in cls.__dict__` ignores inherited
  generated methods for this decision and refreshes the child binding.

Relevant proof obligations: PO3, PO4.

## F4: Ambiguity - Inherited User-Defined Overrides Are Not Specified

Input/state:

- A base class or mixin defines a user method named `get_foo_display()`.
- A subclass defines a local choices field named `foo` but does not define
  `get_foo_display()` directly.

Observed in V1:

- The subclass field contribution sees no direct `get_foo_display()` in
  `cls.__dict__` and installs the generated helper, shadowing the inherited
  method.

Expected from public evidence:

- The issue explicitly demonstrates and debates methods defined directly in the
  model class body. Local docs say Django adds `get_FOO_display()` for choices
  fields. The public evidence does not clearly state whether inherited user
  methods should block generation for a local choices field.

V1 decision:

- No source change. This is an underspecified compatibility question, not a
  justified repair for the reported regression.

Relevant proof obligations: PO6.

## F5: Proof Limitation - Abstract Mini-Model, Not Machine-Checked

Input/state:

- The proof models class dictionaries, inherited lookup, choice-field
  contribution, and generated/helper winner rules.

Observed limitation:

- It does not model full Python descriptor behavior, full Django app registry
  setup, or database behavior.
- K commands were written but not executed.

Expected honesty gate:

- The result is "constructed, not machine-checked"; tests must be kept until a
  real machine check and ordinary test run are available.

V1 decision:

- No source change. The modeled property distinguishes the reported passing
  case from the failing case, so it is adequate for the targeted audit.

Relevant proof obligations: PO7.
