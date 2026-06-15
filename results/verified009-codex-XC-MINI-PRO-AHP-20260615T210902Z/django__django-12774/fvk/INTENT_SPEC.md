# Intent Spec

Status: constructed, not machine-checked.

1. `QuerySet.in_bulk()` should allow a non-primary-key `field_name` when that
   single field is globally unique by `unique=True`.
2. It should also allow a non-primary-key `field_name` when that same single
   field is globally unique by an unconditional one-field `UniqueConstraint`.
3. It should continue to reject non-primary-key fields that are not globally
   unique by themselves.
4. It should not treat a conditional unique constraint as global uniqueness.
5. It should not treat one member of a composite unique constraint as unique by
   itself.
6. Existing query construction and returned dictionary behavior should remain
   unchanged after validation accepts a field.
7. Valid field identifiers for relation fields may be represented by either a
   field name or an attname where Django metadata accepts both forms.
