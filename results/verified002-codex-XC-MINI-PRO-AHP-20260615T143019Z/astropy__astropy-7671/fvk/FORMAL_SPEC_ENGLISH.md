# Formal Spec in English

Status: paraphrase of `fvk/minversion-spec.k`.

## Claim C1

Calling the modeled `minversion` on a module whose version is `1.14.3`, with
required version `1.14dev` and inclusive comparison, returns `True`.

## Claim C2

For any in-domain numeric-prefix installed version and required version,
inclusive `minversion` returns the greater-than-or-equal comparison of their
leading numeric release prefixes.

## Claim C3

For any in-domain numeric-prefix installed version and required version,
exclusive `minversion` returns the strict greater-than comparison of their
leading numeric release prefixes.

## Claim C4

If the module name cannot be imported, `minversion` returns `False` without
performing version comparison.

## Claim C5

If the module argument is not a module object and not a string import name,
`minversion` raises `ValueError`.

## Side Condition S1

The comparison claims range over version strings with leading numeric release
prefixes. Nonnumeric-leading versions and full PEP 440 semantics are outside the
proved domain.

