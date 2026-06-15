# Intent Spec

Status: constructed from public evidence only; not machine-checked.

## Target

`astropy.units.decorators.QuantityInput.__call__.wrapper`, specifically the
return-handling branch after the wrapped function has executed.

## Intended Behavior

I-ARG: Argument validation remains the responsibility of `quantity_input`.
Argument annotations and decorator keyword targets continue to validate units
before the wrapped function is called.

Evidence: the decorator docstring says the decorator validates function
arguments, and the V1 change does not touch argument validation.

I-RET-UNIT: A return annotation that is a unit target remains a unit-conversion
request. If the wrapped function returns a quantity and the annotation is a
unit-like object, the wrapper returns `return_.to(annotation)`.

Evidence: the decorator docstring says a return annotation causes the function
to always return a `Quantity` in that unit, with the example
`def myfunction(myangle: u.arcsec) -> u.deg**2`.

I-RET-EMPTY: If there is no return annotation, the wrapper returns the wrapped
function's return value unchanged.

Evidence: this is the existing public behavior implied by `quantity_input` being
an argument validator unless return conversion is requested.

I-RET-NONE: A Python return annotation of exactly `None` means "this function
returns nothing", not "convert to unit None". The wrapper must not call `.to`
because of that annotation and must return the wrapped function's return value
unchanged. For constructors, that value is `None`.

Evidence: the public issue title says "`quantity_input` decorator fails for
constructors with type hinted return value -> None"; the reproducer annotates
`__init__(..., voltage: u.V) -> None`; the problem statement calls `None` the
correct return value for the constructor and reports `AttributeError:
'NoneType' object has no attribute 'to'` as the bug.

I-FRAME: The fix must not change the public decorator API, the wrapped function
signature, the argument validation semantics, or unit-return conversion for
non-`None` annotations.

Evidence: the issue is scoped to the return annotation `None`; public docs and
tests already rely on unit-return conversion.

## Domain

The in-domain cases for this audit are runtime Python annotations as exposed by
`inspect.signature` in the reported Python 3.6 scenario:

- `inspect.Signature.empty` for no return annotation;
- `None` for `-> None`;
- a unit-like non-`None` object for unit return conversion.

Stringified annotations from `from __future__ import annotations`, annotations
such as `typing.Optional`, and static type-checking enforcement are outside this
issue's public evidence. They are noted as residual ambiguity, not as code
obligations for this fix.
