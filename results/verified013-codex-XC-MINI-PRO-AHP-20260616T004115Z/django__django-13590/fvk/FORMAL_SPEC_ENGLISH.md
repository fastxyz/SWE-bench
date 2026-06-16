# Formal Spec in English

This paraphrases `resolve-lookup-value-spec.k`.

## CLAIM-EXPRESSION

Resolving an expression-like value returns that value's abstract resolved form.

## CLAIM-SCALAR

Resolving a non-expression scalar returns the scalar unchanged.

## CLAIM-LIST

Resolving a list returns a list whose elements are the recursive resolutions of
the input elements in the same order.

## CLAIM-PLAIN-TUPLE

Resolving a plain tuple returns a plain tuple whose elements are the recursive
resolutions of the input elements in the same order.

## CLAIM-NAMED-TWO-TUPLE-RANGE

Resolving a standard two-field named tuple used as a range value returns a named
tuple with the same name/type marker and with the two resolved elements supplied
as positional fields. It does not model or permit the pre-fix behavior of
passing one iterator object as the first positional field.

## CLAIM-NAMED-TUPLE-GENERAL

Resolving a standard named tuple of any finite arity returns the same named
tuple shape with each element recursively resolved in order.
