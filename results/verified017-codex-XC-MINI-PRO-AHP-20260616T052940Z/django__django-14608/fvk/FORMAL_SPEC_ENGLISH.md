# Formal Spec English

Status: constructed from the K claims in `formset-nonform-spec.k`.

## Claim C1: `NONFORM-UNBOUND`

If `non_form_errors()` is evaluated on an unbound formset in the modeled
domain, the returned list has no errors and its rendered CSS class is
`errorlist nonform`.

## Claim C2: `NONFORM-CLEAN`

If `non_form_errors()` is evaluated on a bound formset with no formset-level
validation errors, the returned list has no errors and its rendered CSS class
is `errorlist nonform`.

## Claim C3: `NONFORM-MANAGEMENT`

If `non_form_errors()` is evaluated on a bound formset with a management-form
error, the returned list contains the management-form error and its rendered
CSS class is `errorlist nonform`.

## Claim C4: `NONFORM-VALIDATION`

If `non_form_errors()` is evaluated on a bound formset whose max/min/custom
formset validation raises `ValidationError`, the returned list contains the
validation errors and its rendered CSS class is `errorlist nonform`.

## Claim C5: `PREFIX-DISCRIMINATOR`

The pre-fix construction that omits the extra class renders as the base
`errorlist` class, not `errorlist nonform`. Therefore the formal observable can
distinguish the bug from the fixed behavior.
