# FVK Specification

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited production unit is `ForeignKey.validate()` in
`repo/django/db/models/fields/related.py`. The observable behavior under audit
is whether a submitted foreign key value is accepted or rejected during model
validation when the related model's default manager filters out rows that its
base manager can see.

## Public intent ledger

| ID | Evidence | Obligation |
| --- | --- | --- |
| E1 | "`ForeignKey.validate()` should validate using the base manager instead of the default manager." | Use `_base_manager` for the related existence query. |
| E2 | The example form deliberately sets `Article._base_manager.all()`. | A form-selected base-visible row must survive model FK validation. |
| E3 | The reported invalid error says the archived article "does not exist." | Validation must not confuse default-manager filtering with row absence. |
| E4 | Public hint: ORM validation avoids DB errors, not archived business logic. | The check is existence-level, not policy-level. |
| E5 | Public hint: "This is a change to model validation." | Repair the ORM field validation path, not form defaults. |
| E6 | Existing code applies `complex_filter(self.get_limit_choices_to())`. | Preserve explicit relation limits. |
| E7 | Related descriptors use `_base_manager` to dereference related rows. | `_base_manager` is compatible with relation resolution. |
| E8 | Existing code computes `using = router.db_for_read(...)`. | Preserve database routing behavior. |

## Contract

O1. For any non-`None` submitted FK value `v`, after normal field validation
passes, `ForeignKey.validate()` must build the related existence query from
`remote_field.model._base_manager` on the routed database.

O2. If the base-manager query has a row for
`remote_field.field_name == v` and `limit_choices_to` allows it, validation
must accept `v`.

O3. If no row exists through `_base_manager`, validation must raise the existing
invalid `ValidationError`.

O4. If a row exists through `_base_manager` but `limit_choices_to` excludes it,
validation may raise the existing invalid `ValidationError`.

O5. Parent-link early return, `None` handling, database routing, target-field
filtering, and error payload shape are frame conditions outside the manager
change.

## Formal model

The K model in `mini-django-validation.k` abstracts the existence query to:

`ValidateFK(manager, value, baseExists, defaultExists, limitAllows) -> Outcome`

This model preserves the property under test: a passing instance
`baseExists=true, defaultExists=false, limitAllows=true` maps to `Valid` only
when `manager=BaseManager`, while the failing legacy instance maps to `Invalid`
when `manager=DefaultManager`.

## Adequacy conclusion

The formal claims in `foreignkey-validate-spec.k` match the intent obligations
above. The proof is partial correctness over the manager-selection behavior and
does not claim full Django execution semantics.
