# FVK Specification: django__django-14238

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited behavior is the compatibility check implemented by
`AutoFieldMeta.__subclasscheck__()` and consumed by
`Options._get_default_pk_class()` through `issubclass(pk_class, AutoField)`.
There are no loops or recursive functions in this audited fragment.

Formal core:

- `fvk/mini-python-autofield.k`
- `fvk/autofield-meta-spec.k`

## Intent Specification

1. A class used as `DEFAULT_AUTO_FIELD` is valid when it is a subclass of
   `AutoField`, or when Django's compatibility metaclass treats it as one
   because it inherits from `BigAutoField` or `SmallAutoField`.
2. The `BigAutoField` and `SmallAutoField` compatibility obligation is a family
   obligation: subclasses of those classes, including indirect subclasses, must
   pass the same `issubclass(C, AutoField)` check as the concrete classes.
3. Invalid default auto field classes, such as `TextField`, must still be
   rejected with the existing `ValueError` path.
4. Empty and import-failing `DEFAULT_AUTO_FIELD` settings are separate error
   branches and must remain `ImproperlyConfigured`.
5. Existing public compatibility behavior must be preserved: the
   `__subclasscheck__(self, subclass)` signature is unchanged, direct
   `AutoField` subclasses still pass through `super().__subclasscheck__()`, and
   `isinstance(..., AutoField)` behavior remains governed by the already
   subclass-aware `__instancecheck__()`.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "DEFAULT_AUTO_FIELD subclass check fails for subclasses of BigAutoField and SmallAutoField." | Subclasses of both compatibility roots must be accepted by `issubclass(C, AutoField)`. | Encoded by O1, O2, O5, O6, O7. |
| E2 | `benchmark/PROBLEM.md` | Reproducer defines `class MyBigAutoField(models.BigAutoField)` and receives "must subclass AutoField." | `MyBigAutoField`-like classes are in-domain and the ValueError is the buggy observed behavior. | Encoded by O5 and legacy witness O10. |
| E3 | `benchmark/PROBLEM.md` | "This can be fixed in AutoFieldMeta.__subclasscheck__ by allowing subclasses of those classes in the _subclasses property." | The fix belongs in metaclass subclass compatibility, not only in `_get_default_pk_class()`. | Encoded by O1/O2 generic metaclass claims. |
| E4 | `repo/django/db/models/fields/__init__.py` | `_subclasses` returns `(BigAutoField, SmallAutoField)`. | The compatibility roots are exactly those two classes. | Encoded in the mini semantics and O1/O2. |
| E5 | `repo/django/db/models/fields/__init__.py` | The metaclass comment says it maintains "backward inheritance compatibility for AutoField." | Preserve direct `AutoField` subclass behavior and existing compatibility checks. | Encoded by O3 and compatibility audit. |
| E6 | `repo/django/db/models/options.py` | `_get_default_pk_class()` rejects when `not issubclass(pk_class, AutoField)`. | The observable bug is the truth value returned by `issubclass(pk_class, AutoField)`. | Encoded by O5-O9. |
| E7 | `repo/tests/model_options/test_default_pk.py` | `DEFAULT_AUTO_FIELD='django.db.models.TextField'` raises "must subclass AutoField." | Non-auto fields remain rejected. | Encoded by O4 and O8. |
| E8 | `repo/tests/model_options/test_default_pk.py` | Nonexistent and `None` default auto fields raise `ImproperlyConfigured`. | Import/empty failures must be preserved. | Encoded by O9. |
| E9 | `repo/tests/model_fields/test_autofield.py` | Public tests assert `issubclass(BigAutoField, AutoField)` and `issubclass(SmallAutoField, AutoField)`. | The concrete compatibility roots must continue passing. | Covered by O1/O2 with reflexive subclassing. |
| E10 | `repo/tests/custom_pk/fields.py` | Public tests define `class MyAutoField(models.BigAutoField)`. | Custom subclasses of `BigAutoField` are a public, plausible field shape. | Supports O1/O5. |

## Formal Model

The mini semantics abstracts Python classes as `Class` values with a
`subclassOf(C, R)` relation. It models only the audited observable:

- `tupleSubclassCheck(C)` is Python's `issubclass(C, (BigAutoField,
  SmallAutoField))`;
- `superAutoFieldSubclassCheck(C)` is the direct `type.__subclasscheck__`
  fallback for real `AutoField` inheritance;
- `autoFieldSubclassCheck(C)` is the V1 production expression;
- `defaultPkCheck(imported(C))` models the validation branch of
  `_get_default_pk_class()`;
- `legacyExactTupleCheck(C)` models the pre-fix exact membership behavior as a
  bug witness.

The model keeps the property axis visible: a class inheriting from
`BigAutoField` or `SmallAutoField` maps differently from `textField`, so the
abstraction distinguishes passing and failing instances.

## Formal Specification In English

- O1: For every class `C`, if `C` is a subclass of `BigAutoField`, then
  `autoFieldSubclassCheck(C)` returns true.
- O2: For every class `C`, if `C` is a subclass of `SmallAutoField`, then
  `autoFieldSubclassCheck(C)` returns true.
- O3: For every class `C`, if `C` is a direct Python subclass of `AutoField`,
  then `autoFieldSubclassCheck(C)` returns true through the `super()` fallback.
- O4: For every class `C` that is not a subclass of `BigAutoField`,
  `SmallAutoField`, or `AutoField`, `autoFieldSubclassCheck(C)` returns false.
- O5-O7: `DEFAULT_AUTO_FIELD` validation accepts representative direct and
  indirect custom subclasses of the compatibility roots.
- O8: `DEFAULT_AUTO_FIELD` validation rejects `textField` with the ValueError
  branch.
- O9: import failure and empty default field paths remain
  `ImproperlyConfigured`.
- O10: the pre-fix exact-membership rule rejects `customBigAutoField`,
  explaining the reported bug.

## Adequacy Audit

| Obligation | Public Intent Match | Result |
| --- | --- | --- |
| O1/O2 subclass family acceptance | Directly entailed by E1 and E3. | Pass |
| O3 direct `AutoField` fallback | Required by E5 frame compatibility and the unchanged `super()` call. | Pass |
| O4 non-auto rejection | Required by E7 and absence of public evidence to widen accepted classes beyond auto-field roots. | Pass |
| O5-O7 default validation accepts custom roots | Directly entailed by E1/E2 and family closure from E3. | Pass |
| O8 non-auto default validation rejects | Required by E7. | Pass |
| O9 import/empty error preservation | Required by E8 and untouched code branches. | Pass |
| O10 legacy witness | Matches the reported pre-fix symptom; used only as a bug witness, not a behavior to preserve. | Pass |

No formal claim depends on hidden tests, benchmark verdicts, or upstream patch
knowledge. No order or winner rule is introduced.

## Public Compatibility Audit

Changed public symbol: `AutoFieldMeta.__subclasscheck__(self, subclass)`.

- Signature: unchanged.
- Return type: unchanged boolean behavior.
- Accepted class family: intentionally widened from exact
  `BigAutoField`/`SmallAutoField` membership to subclasses of those roots.
- Existing concrete roots: preserved by reflexive subclassing.
- Direct `AutoField` subclasses: preserved by the unchanged `super()` fallback.
- `__instancecheck__`: unchanged; it already uses `isinstance(instance,
  self._subclasses)`, which includes subclass instances.
- Public callsites found: `Options._get_default_pk_class()` is the only source
  callsite using `issubclass(..., AutoField)`. Existing `isinstance(...,
  AutoField)` callsites are unaffected.

Compatibility audit result: pass.
