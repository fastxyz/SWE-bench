# Formal Spec English

Status: constructed for FVK audit, not machine-checked.

This file paraphrases the formal claims in `permutation-subclass-spec.k`.

K1. For any class tag `C` and valid array form `A`, `afNew(C, A)` terminates
with `obj(C, A)`. Plain English: the fast constructor allocates the class it is
called on and preserves the array payload.

K2. For any class tag `C`, valid array form `A`, and constructor fast-path
case, `constructorFast(C, case, A)` terminates with `obj(C, A)`. Plain English:
the `__new__` branches that delegate to `_af_new` preserve the requested class.

K3. For array/cyclic-form construction that reaches the ordinary
`Basic.__new__(cls, aform)` path, `constructorArray(C, A)` terminates with
`obj(C, A)`. Plain English: the non-fast allocation path already preserves
`cls`.

K4. Constructing requested subclass `Sub` from an existing base `Perm` object
with the same size terminates with `obj(Sub, A)`. Plain English: a subclass
constructor must not return a base instance merely because the input was a base
`Permutation`.

K5. Constructing requested base `Perm` from an existing subclass object with the
same size terminates with that existing subclass object. Plain English: V1
preserves the legacy "return the object itself when already an instance of the
requested class" behavior.

K6. An instance operation invoked on `obj(C, oldA)` that creates a fresh array
form `A` terminates with `obj(C, A)`. Plain English: inherited operations using
the helper preserve the receiver's class.

K7. A classmethod-like operation invoked on class `C` that creates a fresh array
form `A` terminates with `obj(C, A)`. Plain English: classmethod constructors
such as unranking or random construction preserve the class they are called on.

K8. A module-level alias bound from `Permutation._af_new` terminates with
`obj(Perm, A)`. Plain English: external aliases that deliberately bind the base
helper continue to produce base `Permutation` objects.

