# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited production change is the V1 edit in
`repo/django/db/models/enums.py`: `ChoicesMeta.__new__()` assigns
`do_not_call_in_templates = True` to each created choices enum class.

The proof scope is intentionally narrow and property-complete for the issue:
it models choices enum class creation, the template callable gate, and dotted
member lookup. It does not model unrelated template features.

## Intent Ledger Summary

- E-001 and E-002 require choices enum classes to be usable in templates, with
  `YearInSchool.FRESHMAN` resolving to the member.
- E-003 localizes the pre-fix failure to the callable gate on the intermediate
  enum class.
- E-004 requires the existing `do_not_call_in_templates` mechanism.
- E-005 and E-006 define the public behavior of that mechanism: preserve the
  callable object and continue normal attribute lookup.
- E-007 supports assigning the marker after enum class creation, so it is a
  class attribute rather than an enum member.
- E-008 requires public API compatibility for the exported choices classes.

The full ledger is in `PUBLIC_EVIDENCE_LEDGER.md`.

## Formal Model

The K-style model is split into:

- `mini-django-template.k`: an abstract semantics for choices class creation,
  a template `lookup`, a template `callGate`, and enum-class `attr` lookup.
- `choices-template-spec.k`: claims over that model.

The model preserves the defect's observable axis:

- whether a value is callable as an enum class;
- whether that callable class has the `do_not_call_in_templates` marker;
- whether the following dotted member lookup can still read the class member.

It deliberately abstracts away unrelated template rendering, string coercion,
and model field storage.

## Claims

1. `CHOICES-CREATION-MARKS`: creating a choices class through
   `ChoicesMeta.__new__()` yields an enum class whose marker bit is `true`.
2. `TEMPLATE-ENUM-MEMBER-LOOKUP`: resolving
   `YearInSchool.FRESHMAN` where `YearInSchool` is a marked enum class yields
   the `FRESHMAN` member.
3. `UNMARKED-ENUM-CLASS-FAILS`: the same lookup with an unmarked enum class
   reaches `invalid` after the callable gate. This is a diagnostic claim that
   localizes the pre-fix bug; it is not a desired V2 behavior.
4. `CHOICES-MEMBER-FRAME`: the marker assignment preserves the member map.

## Preconditions

1. The template context contains a `YearInSchool` binding to a choices enum
   class.
2. The enum class contains a `FRESHMAN` member.
3. The value under audit is a `models.Choices` family enum class, i.e. it was
   created by `ChoicesMeta`.

These preconditions are intent-derived from the issue example and public
choices API. They are not copied from V1.

## Postconditions

1. Every `ChoicesMeta`-created class has
   `do_not_call_in_templates == True`.
2. Template variable resolution does not call such a class.
3. Dotted lookup continues from the preserved class to the requested enum
   member.
4. Enum members and member metadata are unchanged by the marker assignment.

## Adequacy

The adequacy gate passes: the English meaning of each K claim is entailed by
`INTENT_SPEC.md` and the public evidence ledger. No claim preserves a legacy
bug or depends on hidden/evaluator evidence.
