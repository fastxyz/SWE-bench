# FVK Specification

Status: constructed, not machine-checked.

## Scope

This audit targets the V1 fix for `django__django-14672`:

- `repo/django/db/models/fields/reverse_related.py`
- `ManyToManyRel.identity`
- the interaction with `ForeignObjectRel.__hash__()` and
  `django.utils.hashable.make_hashable()`

The audit does not attempt to verify all of Django. It verifies the slice whose
observable behavior is named by the public issue: hashing and comparing a
`ManyToManyRel` whose `through_fields` value may be a list.

## Intent Spec

1. `ManyToManyRel.identity` must be usable by `ForeignObjectRel.__hash__()`.
2. `through_fields` is allowed to be a list of field names.
3. A list-valued `through_fields` must not make model checks fail with
   `TypeError: unhashable type: 'list'`.
4. The fix should mirror the existing `limit_choices_to` normalization pattern:
   normalize unhashable identity elements with `make_hashable()`.
5. The stored `self.through_fields` attribute should remain available to existing
   callers that use length checks, indexing, and slicing.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "identity property has been added ... to compare them" | Relation identity must support equality and hashing. | Encoded in PO-1 and PO-2. |
| E2 | `benchmark/PROBLEM.md` | "through_fields can be a list" | List-valued `through_fields` is in domain. | Encoded in PO-1. |
| E3 | `benchmark/PROBLEM.md` | traceback reaches `return hash(self.identity)` with `TypeError: unhashable type: 'list'` | The list must not remain inside the hash path. | Encoded in PO-1 and finding F-001. |
| E4 | `benchmark/PROBLEM.md` | "Solution: Add missing make_hashable call on self.through_fields in ManyToManyRel." | The intended repair point is `ManyToManyRel.identity`, not broad hash behavior. | Encoded in PO-2 and decision D-001. |
| E5 | `repo/django/db/models/fields/reverse_related.py` | base `ForeignObjectRel.identity` calls `make_hashable(self.limit_choices_to)` | Existing design normalizes unhashable identity elements locally. | Encoded in PO-2. |
| E6 | `repo/django/db/models/fields/related.py` | validation uses `len(self.remote_field.through_fields)`, index `0`/`1`, and slice `[:2]` | Avoid mutating the stored attribute in a way that broadens behavior. | Encoded in PO-3 and finding F-003. |
| E7 | `repo/django/db/models/base.py` | `_check_field_name_clashes()` uses `if f not in used_fields` | Reverse relation objects can be hashed during checks. | Encoded in PO-1 and proof step P-002. |

## Formal Spec English

For any `ManyToManyRel` in the issue domain where the base relation identity
elements are hashable after their existing normalization, `identity` returns:

```text
ForeignObjectRel.identity(self)
+ (self.through, make_hashable(self.through_fields), self.db_constraint)
```

If `self.through_fields` is `['child', 'parent']`, the identity contribution is
`('child', 'parent')`, so hashing the full identity cannot fail merely because
`through_fields` was provided as a list.

If `self.through_fields` is already a tuple of the same field names, the identity
contribution remains that tuple. Therefore list and tuple spellings of the same
field-name sequence contribute the same comparable identity value.

Evaluating `identity` does not assign back to `self.through_fields`.

## Adequacy Audit

| Claim | Intent match | Reason |
| --- | --- | --- |
| Normalize `through_fields` inside `ManyToManyRel.identity`. | Pass | Directly supported by E2, E3, and E4. |
| Require identity hashability for list-valued `through_fields`. | Pass | Directly supported by E1, E2, E3, and E7. |
| Preserve `self.through_fields` as stored. | Pass | Supported by E6 and by the absence of public intent to change attribute storage. |
| Change `ForeignObjectRel.__hash__()` globally. | Rejected | Broader than E4 and unnecessary for the described defect. |
| Convert `through_fields` in `ManyToManyRel.__init__`. | Rejected | Could satisfy hashability but would change stored attribute behavior beyond E4. |

## Public Compatibility Audit

Changed symbol: `ManyToManyRel.identity`.

Compatibility result: acceptable and intended. The returned identity tuple changes
only for unhashable `through_fields` values by replacing them with their
`make_hashable()` equivalent. This is the property identity needs in order to be
hashable and comparable. The stored `self.through_fields` attribute is unchanged,
so validation and relation-resolution code that indexes or slices it continues to
see the caller-provided sequence.

No method signature, public call pattern, or test file is modified.
