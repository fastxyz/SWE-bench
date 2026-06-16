# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F1: Exact Membership Caused The Reported Rejection

Input:

```python
class MyBigAutoField(models.BigAutoField):
    pass

DEFAULT_AUTO_FIELD = "example.core.models.MyBigAutoField"
```

Observed pre-fix behavior:

`legacyExactTupleCheck(customBigAutoField) == false`, so
`_get_default_pk_class()` reaches the ValueError branch: "must subclass
AutoField."

Expected behavior:

`autoFieldSubclassCheck(customBigAutoField) == true`, so
`defaultPkCheck(imported(customBigAutoField)) == accepted(customBigAutoField)`.

Classification: code bug in legacy implementation, resolved by V1.

Evidence: SPEC E1-E3, E10. Proof obligations: O1, O5, O10.

## F2: The Fix Must Cover The Whole Compatibility Root Family

Input examples:

- `customBigAutoField` inheriting from `bigAutoField`
- `customSmallAutoField` inheriting from `smallAutoField`
- `indirectCustomBigAutoField` inheriting from a custom `bigAutoField`
  subclass

Observed V1 behavior:

Each example satisfies `issubclass(C, (BigAutoField, SmallAutoField))` in the
modeled semantics, therefore `autoFieldSubclassCheck(C) == true`.

Expected behavior:

All subclasses of the classes in `_subclasses` are accepted by the compatibility
check, not only the two exact root classes.

Classification: family completeness check, discharged by V1.

Evidence: SPEC E1, E3, E4. Proof obligations: O1, O2, O6, O7.

## F3: Negative Validation Behavior Is Preserved

Input:

```python
DEFAULT_AUTO_FIELD = "django.db.models.TextField"
```

Observed V1 behavior:

`autoFieldSubclassCheck(textField) == false`, so
`defaultPkCheck(imported(textField)) == valueError`.

Expected behavior:

The existing "must subclass AutoField" ValueError remains for non-auto field
classes.

Classification: frame condition, discharged by V1.

Evidence: SPEC E7. Proof obligations: O4, O8.

## F4: Import And Empty-Path Errors Are Unchanged

Inputs:

- nonexistent default auto field path
- empty or `None` default auto field path

Observed V1 behavior:

The V1 patch only changes `AutoFieldMeta.__subclasscheck__()`. It does not edit
the import error or empty-path branches in `_get_default_pk_class()`.

Expected behavior:

Both remain `ImproperlyConfigured`.

Classification: frame condition, discharged by source inspection and the model.

Evidence: SPEC E8. Proof obligation: O9.

## F5: No Additional Source Change Is Justified By FVK

Candidate alternatives audited:

- Change `_get_default_pk_class()` to special-case `BigAutoField` and
  `SmallAutoField` subclasses.
- Change `_subclasses` instead of `__subclasscheck__()`.
- Add a new guard around the `issubclass()` call inside `__subclasscheck__()`.

Decision:

No alternative is justified. The issue and code comment point to
`AutoFieldMeta.__subclasscheck__()`, and V1 fixes the public `issubclass(C,
AutoField)` compatibility surface for all consumers, not only
`DEFAULT_AUTO_FIELD`. `_subclasses` already identifies the intended roots. A
new non-class guard would address direct misuse of `__subclasscheck__`, which is
outside the issue's class-input domain and not required by the public evidence.

Classification: no code bug found in V1.

Evidence: SPEC E3-E6 and compatibility audit. Proof obligations: O1-O11.

## F6: Proof Is Constructed, Not Machine-Checked

The K semantics and claims have been written, but this session forbids running
`kompile`, `kast`, or `kprove`.

Classification: proof validation gap, not a source-code bug.

Recommended next step outside this benchmark constraint:

```sh
kompile fvk/mini-python-autofield.k --backend haskell
kast --backend haskell fvk/autofield-meta-spec.k
kprove fvk/autofield-meta-spec.k
```

Tests should not be removed unless the machine check succeeds.
