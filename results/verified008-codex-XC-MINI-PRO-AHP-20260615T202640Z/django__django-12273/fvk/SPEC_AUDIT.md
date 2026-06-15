# Specification Audit

Status: pass, constructed and not machine-checked.

## SET-PK-CHAIN

- Formal English: every field in the finite primary-key parent-link chain is
  set to the assigned value.
- Intent match: pass.
- Evidence: public hints require `self.pk = None` to set both the child
  parent-link field and the inherited parent PK, and to work for several levels
  of inheritance.

## SAVE-CONSEQUENCE

- Formal English: clearing the chain to `None` prevents the parent save path
  from treating the old parent row as an update target.
- Intent match: pass.
- Evidence: issue symptom is that the old object is overwritten on `save()`;
  `_save_table()` statically shows update is attempted only when the relevant
  PK value is set.

## Frame and compatibility condition

- Formal English: ordinary PK assignment is unchanged, and non-primary parent
  links are not reset by the `pk` setter.
- Intent match: pass.
- Evidence: public discussion rejects an all-parent patch because it fails for
  multiple-model inheritance and causes other failures; model options allow a
  parent link that is not the child primary key.

## Residual ambiguity

Direct inherited field assignment such as `derived.uid = None` remains outside
the proven contract. The public issue starts with such an example, but the
discussion explicitly reframes the reliable API as `derived.pk = None`.
