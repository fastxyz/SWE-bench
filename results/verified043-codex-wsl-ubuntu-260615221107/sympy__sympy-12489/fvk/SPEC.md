# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 fix for `sympy__sympy-12489`: `Permutation`
subclass construction and helper allocation must preserve the class through
which construction is invoked. The formal model intentionally abstracts away
permutation algebra and validation details, because the issue is about object
class identity, `_array_form` payload preservation, and helper dispatch.

The formal core is in:

- `fvk/mini-python.k`
- `fvk/permutation-subclass-spec.k`

The exact machine-check commands are recorded in `fvk/PROOF.md`; they were not
run.

## Intent-Only Contract

- Constructing a valid permutation through subclass `C` must return an object
  whose class is `C` on all fresh-allocation constructor paths.
- Calling `C._af_new(valid_array)` must return class `C`, with `_array_form`
  equal to the supplied array and `_size == len(array)`.
- Constructing subclass `C` from an existing base `Permutation` of the same
  size must not return the base object; it must allocate class `C`.
- Constructing base `Permutation` from an existing subclass object may preserve
  the existing object, matching legacy identity behavior.
- Inherited methods and classmethods that allocate fresh permutation instances
  from array forms should preserve the receiver or called class.
- External module-level aliases bound from `Permutation._af_new` continue to
  produce base `Permutation` objects.

## Public Evidence Ledger

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1: The issue says "`combinatorics.Permutation` can't be subclassed
  properly", imposing subclass-preserving construction.
- E2: The issue identifies `Basic.__new__(Perm, perm)` inside `_af_new` as the
  defect mechanism.
- E4: The public hint says `_af_new` should be a classmethod using
  `Basic.__new__(cls, perm)`.
- E5: The constructor docstring enumerates multiple construction forms, so the
  obligation covers all fresh-allocation branches, not a single reproducer.
- E6: Existing external aliases bind `Permutation._af_new`; these are a
  compatibility frame condition.

## Formal Abstraction

The K model uses class tags:

- `Perm` for `Permutation`
- `Sub` for an arbitrary subclass

Objects are abstracted as `obj(Class, List)`, preserving only the class identity
and array payload. This abstraction is property-complete for this issue because
the reported defect distinguishes passing and failing cases solely by the class
tag of the allocated object:

- Passing: `Sub._af_new(A) -> obj(Sub, A)`
- Failing legacy behavior: `Sub._af_new(A) -> obj(Perm, A)`

Those map to different model values.

## Claims

K1. `_af_new` preserves called class and array payload.

K2. `Permutation.__new__` fast paths that delegate to `_af_new` preserve `cls`.

K3. The array/cyclic-form fallthrough path using `Basic.__new__(cls, aform)`
preserves `cls`.

K4. Subclass construction from an existing base `Permutation` returns the
subclass.

K5. Base construction from an existing subclass preserves the existing subclass
object when it is already an instance of the requested class.

K6. Instance operations that create a fresh permutation from an array form
preserve the receiver class.

K7. Classmethods that create a fresh permutation from an array form preserve the
called class.

K8. Module-level aliases bound from `Permutation._af_new` continue to construct
base `Permutation`.

## Adequacy

The adequacy files are:

- `fvk/INTENT_SPEC.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

All formal-English claims pass against the intent spec. No behavior needed to
justify V1 is marked fail or ambiguous.

