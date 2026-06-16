# FVK Spec

Status: constructed, not machine-checked.

## Scope

Target function: `django.template.defaultfilters.floatformat`.

This FVK pass verifies the precision-relevant conversion slice of
`floatformat`: whether a value that is already a `Decimal` reaches the existing
rounding and formatting code unchanged. Full Python `decimal.Decimal` arithmetic,
Django localization, and `formats.number_format()` are modeled as trusted
external functions with explicit proof obligations because no execution or K
tooling is available in this task.

## Intent-derived contract

For any finite `Decimal` value `D` and any integer decimal-place argument `P`
after `g`/`u` suffix normalization, `floatformat(D, P)` must render the result
of Django's existing `Decimal` rounding path applied to the exact value `D`.
It must not render the result of converting `D` to `float` and then back to
`Decimal`.

For the concrete issue point:

```
floatformat(Decimal("42.12345678901234567890"), 20)
    == "42.12345678901234567890"
```

Frame conditions:

* Non-Decimal inputs continue through the existing `repr()` parse path and
  `float()` fallback.
* The `g` and `u` suffix handling remains unchanged.
* The public signature, decorators, and return protocol remain unchanged.
* Tests are not modified.

## Public intent ledger summary

Critical ledger entries are mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md` and as
`SPEC-PROVENANCE` comments in `fvk/floatformat-spec.k`.

* E-1/E-3: the issue identifies `Decimal` precision loss caused by conversion
  through `float`.
* E-2: the issue's concrete value fixes the expected output at 20 places.
* E-4/E-5: Django docs define rounding, decimal-place, grouping, and
  localization behavior.
* E-6/E-7: public tests make Decimal input in-domain and require non-Decimal
  behavior to stay framed.

## Adequacy

The formal claims do not prove all of Django's template rendering. They prove
the defect axis: existing `Decimal` values are not reparsed from their Python
`repr()` and are not converted through binary float before the existing
rounding/formatting path.
