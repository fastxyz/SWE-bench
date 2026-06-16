# Proof Obligations

Status: constructed, not machine-checked.

## PO1: `_af_new` Class Preservation

For every class `C` and valid array form `A`, calling `_af_new` through `C`
returns an object with class `C`, `_array_form == A`, and `_size == len(A)`.

Source evidence: E2, E3, E4.

V1 discharge: `@classmethod def _af_new(cls, perm)` and
`Basic.__new__(cls, perm)`.

Formal claim: `afNew(C, A) => obj(C, A)`.

## PO2: `__new__` Fast-Path Class Preservation

For every class `C`, every valid normalized array form `A` produced by the
empty, cycle-argument, `Cycle`, singleton, or fast existing-permutation paths of
`__new__`, the returned object has class `C`.

Source evidence: E1, E3, E5.

V1 discharge: those branches call `cls._af_new(...)`.

Formal claim: `constructorFast(C, case, A) => obj(C, A)`.

## PO3: Existing-Permutation Construction

When `C` constructs from an existing permutation object:

- if the input object is already an instance of `C`, returning it is permitted;
- otherwise, for same-size construction, V1 must allocate a new object of class
  `C`;
- for size adjustment, recursive construction must use `cls(...)`, not
  `Perm(...)`.

Source evidence: E1, E3, E5, E7.

V1 discharge: `if isinstance(a, cls): return a; return cls._af_new(a.array_form)`
and `return cls(a.array_form, size=size)`.

Formal claims: `constructExisting(Sub, obj(Perm, A)) => obj(Sub, A)` and
`constructExisting(Perm, obj(Sub, A)) => obj(Sub, A)`.

## PO4: Subclass-Sensitive Fresh Results in Methods

Inherited instance methods and classmethods that create fresh permutation
objects from array forms preserve the receiver/called class.

Source evidence: E1, E3.

V1 discharge: methods use `self._af_new`, `cls._af_new`, or
`self.__class__` instead of the module-level base alias where a dynamic class is
available.

Formal claims: `operationFresh(obj(C, oldA), A) => obj(C, A)` and
`classmethodFresh(C, A) => obj(C, A)`.

## PO5: External Base Alias Frame

Existing modules that bind `Permutation._af_new` as a module-level helper remain
base-class constructors.

Source evidence: E6.

V1 discharge: no external alias was rewritten; aliases bind the classmethod from
`Permutation`, so the bound class remains `Permutation`.

Formal claim: `moduleAliasAfNew(A) => obj(Perm, A)`.

## PO6: Array and Size Frame Conditions

The fix must not change the array payload or size stored on a constructed
permutation.

Source evidence: E7.

V1 discharge: `_af_new` still assigns `p._array_form = perm` and
`p._size = len(perm)`; `__new__` fallthrough still assigns the same values.

Formal coverage: payload `A` is preserved in all object claims. Length is noted
as a source-level frame condition because the mini-K abstraction models payload,
not integer length.

## PO7: Public Compatibility

Public call shapes for `_af_new` and `rmul_with_af` remain compatible, and
public source callsites do not require signature changes.

Source evidence: E6 and source inspection.

V1 discharge: classmethod binding preserves one-argument class calls and
`*args` call shape for `rmul_with_af`.

Formal coverage: compatibility audit, not a K reachability claim.

## PO8: Honesty Gate

The proof is constructed, not machine-checked. No test, Python, or K command is
executed in this session.

Source evidence: E8.

V1 discharge: commands are recorded in `PROOF.md` only.

