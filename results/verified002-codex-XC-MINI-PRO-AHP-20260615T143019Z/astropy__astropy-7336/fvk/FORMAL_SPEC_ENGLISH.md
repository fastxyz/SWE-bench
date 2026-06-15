# Formal Spec in English

Status: constructed, not machine-checked.

## K Claim Paraphrases

QI-NONE: Starting from a wrapper return-handling state with return annotation
`noneAnn` and wrapped result `noneRet`, execution finishes by returning
`noneRet`. It does not evaluate `.to(...)`.

QI-NONE-ANY: Starting from a wrapper return-handling state with return
annotation `noneAnn` and any modeled wrapped result `R`, execution finishes by
returning `R` unchanged. The decorator does not treat Python's `None`
annotation as a unit target.

QI-EMPTY: Starting from a wrapper return-handling state with no return
annotation and any modeled wrapped result `R`, execution finishes by returning
`R` unchanged.

QI-UNIT: Starting from a wrapper return-handling state with a non-`None`
unit-like return annotation `unitAnn(To)` and a quantity result
`quantity(From)`, execution calls the modeled `.to(...)` operation and finishes
with a converted quantity in unit `To`.

QI-OLD-BUG: Starting from the pre-fix branch condition, where every non-empty
return annotation is treated as a conversion target, the state
`buggyWrapper(noneAnn, noneRet)` reaches the modeled `AttributeError` outcome
`attrError("NoneType.to")`.

## Side Conditions

The claims assume the wrapper has already completed argument binding,
argument-unit validation, entered the equivalency context, and obtained the
wrapped function's return value. Those steps are framed because V1 does not edit
them.

No loop or recursive circularity is present.
