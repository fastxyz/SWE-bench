# Formal Spec English

Status: constructed, not machine-checked.

## K claims

K-01. If `_check_readonly_fields_item()` receives an entry that is not callable,
not an attribute on the admin object, not an attribute on the model class, and
not a model field, it returns one `admin.E035` error whose message representation
contains the indexed label, the invalid field value, the admin class name, and
the model label.

K-02. If `_check_readonly_fields()` checks an invalid entry at any non-negative
index, the caller-created indexed label `readonly_fields[index]` and the invalid
field value both reach the `admin.E035` error message.

K-03. If the `readonly_fields` entry is callable, the item check returns no
errors.

K-04. If the `readonly_fields` entry names an attribute on the admin object, the
item check returns no errors.

K-05. If the `readonly_fields` entry names an attribute on the model class, the
item check returns no errors.

K-06. If the `readonly_fields` entry resolves as a model field, the item check
returns no errors.

## Side conditions and frame conditions

S-01. The indexed-label claim ranges over non-negative indexes, matching Python
enumeration indexes.

S-02. The formal model abstracts the concrete `checks.Error` message string as
`readonlyE035(label, field, admin, model)`. This abstraction is property-complete
for the audited defect because an old-style message without `field` maps to a
different constructor shape and cannot satisfy K-01 or K-02.

S-03. No loop circularity is required for `_check_readonly_fields_item()` because
the changed function has straight-line branching and no loop.
