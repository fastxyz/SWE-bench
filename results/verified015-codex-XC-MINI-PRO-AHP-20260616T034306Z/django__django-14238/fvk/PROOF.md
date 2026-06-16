# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Trusted Base

This proof uses a mini semantics for the audited fragment of Python/Django:
class inheritance, tuple-based `issubclass()`, the `super()` fallback, and the
validation branch of `_get_default_pk_class()`. It does not claim to verify full
Python or full Django.

The abstraction is property-complete for this issue because it distinguishes:

- a class inheriting from `BigAutoField` or `SmallAutoField`;
- a class inheriting directly from `AutoField`;
- a non-auto field class;
- import/empty-path failures that bypass subclass validation.

## No Loop Circularities

The audited code has no loop or recursion. The proof is a straight reachability
argument over K function rewrites and branch side conditions.

## Proof Sketch

### O1: `BigAutoField` Subclass Family

Start with a symbolic class `C` and the precondition
`subclassOf(C, bigAutoField) == true`.

The V1 expression is modeled as:

```text
autoFieldSubclassCheck(C)
=> tupleSubclassCheck(C) orBool superAutoFieldSubclassCheck(C)
=> (subclassOf(C, bigAutoField) orBool subclassOf(C, smallAutoField))
   orBool subclassOf(C, autoField)
```

By the precondition, the first disjunct is true, so the whole expression
rewrites to true. This proves O1.

### O2: `SmallAutoField` Subclass Family

The O2 proof is identical to O1 with the precondition
`subclassOf(C, smallAutoField) == true`. The second tuple disjunct is true, so
`autoFieldSubclassCheck(C)` rewrites to true.

### O3: Direct `AutoField` Subclasses

With precondition `subclassOf(C, autoField) == true`, the tuple disjuncts may be
false, but the modeled `superAutoFieldSubclassCheck(C)` disjunct is true. The
unchanged `super().__subclasscheck__(subclass)` fallback therefore preserves
direct `AutoField` subclass compatibility.

### O4: Non-Auto Classes

With preconditions that `C` is not a subclass of `bigAutoField`,
`smallAutoField`, or `autoField`, all three disjuncts in
`autoFieldSubclassCheck(C)` rewrite to false. The whole expression rewrites to
false, preserving rejection for non-auto field classes.

### O5-O7: `DEFAULT_AUTO_FIELD` Accepts Custom Auto-Field Subclasses

For `customBigAutoField`, the class hierarchy includes:

```text
subclassOf(customBigAutoField, bigAutoField) == true
```

By O1, `autoFieldSubclassCheck(customBigAutoField) == true`. The validation
rule for imported classes then chooses:

```text
defaultPkCheck(imported(customBigAutoField))
=> accepted(customBigAutoField)
```

The same argument applies to `customSmallAutoField` by O2. For
`indirectCustomBigAutoField`, the modeled hierarchy includes transitive
subclassing to `bigAutoField`, so O1 again applies.

### O8: Non-Auto Default Field Rejects

For `textField`, the hierarchy rules make all three compatibility predicates
false. By O4:

```text
autoFieldSubclassCheck(textField) == false
```

The validation rule therefore selects:

```text
defaultPkCheck(imported(textField)) => valueError
```

### O9: Import And Empty-Path Errors

The modeled validation has direct rules:

```text
defaultPkCheck(importError) => improperlyConfigured
defaultPkCheck(emptyPath) => improperlyConfigured
```

The V1 source patch does not edit the corresponding Django branches.

### O10: Legacy Defect Witness

The pre-fix exact-membership model has only two true cases:

```text
legacyExactTupleCheck(bigAutoField) => true
legacyExactTupleCheck(smallAutoField) => true
```

For `customBigAutoField`, the owise rule gives:

```text
legacyExactTupleCheck(customBigAutoField) => false
```

This reconstructs the issue's symptom: the old check rejects a valid custom
subclass before `_get_default_pk_class()` can accept it.

## Completeness Against Public Intent

The proof covers the whole public intent space for this issue:

- subclasses of `BigAutoField`: O1/O5/O7;
- subclasses of `SmallAutoField`: O2/O6;
- direct `AutoField` subclasses: O3;
- invalid non-auto classes: O4/O8;
- import and empty-path errors: O9;
- the specific pre-fix failure mechanism: O10;
- API and instance-check frame conditions: O11 in `PROOF_OBLIGATIONS.md`.

No required behavior is left ambiguous in `SPEC.md`, and no claim preserves the
reported buggy ValueError as desired behavior.

## Test Guidance

Recommended tests to add in a normal development setting:

- `DEFAULT_AUTO_FIELD` accepts a custom subclass of `BigAutoField`.
- `DEFAULT_AUTO_FIELD` accepts a custom subclass of `SmallAutoField`.
- An indirect subclass of a custom `BigAutoField` subclass is accepted.
- Existing non-auto, nonexistent, and empty-path tests remain.

Do not delete tests based on this proof in this session. Any test-redundancy
recommendation is conditioned on a real `kprove` run returning `#Top`.

## Machine Check Commands

Recorded only; not executed:

```sh
kompile fvk/mini-python-autofield.k --backend haskell
kast --backend haskell fvk/autofield-meta-spec.k
kprove fvk/autofield-meta-spec.k
```

Expected machine-checked result: `#Top`.
