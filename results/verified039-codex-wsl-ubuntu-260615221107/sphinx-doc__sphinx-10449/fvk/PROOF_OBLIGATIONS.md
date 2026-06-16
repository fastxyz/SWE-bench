# FVK Proof Obligations

Status: constructed, not machine-checked. The corresponding K-shaped artifacts
are `fvk/mini-autodoc-typehints.k` and `fvk/autodoc-typehints-spec.k`.

## Domain Model

The model abstracts only the part of Sphinx relevant to the reported
observable:

- `ObjType` ranges over `class`, `exception`, `function`, `method`, and
  `other`.
- `Signature` contains a finite list of annotated parameters and an optional
  return annotation.
- `annotations[name]` is the internal map populated by `record_typehints()`;
  the K model represents the relevant `"return"` membership as
  `recordedReturn`.
- `rtypeEmitted` represents whether the later merge emits an `rtype` field.

The abstraction preserves the property under test: whether the annotation map
contains a `"return"` key for the documented object, because
`modify_field_list()` and `augment_descriptions_with_types()` can only produce
`rtype` from such a key.

## PO1: Class Descriptions Do Not Record Constructor Return

For every class object description, annotated parameter list `P`, and return
annotation `R`, starting from no prior annotation entry for the class fullname:

Precondition:

- `objtype == "class"`
- `callable(obj)` and `inspect.signature(obj)` returns parameters `P` and
  return annotation `R`
- no prior `"return"` entry exists for this fullname in
  `env.temp_data['annotations']`

Postcondition:

- all parameter annotations from `P` are present in `annotations[name]`
- `"return"` is absent from `annotations[name]`
- a later type-hint merge has no recorded class return annotation from which to
  create a class-level `rtype`

Public evidence: E1, E2.

## PO2: Exception Descriptions Do Not Record Constructor Return

Same as PO1, with `objtype == "exception"`.

Public evidence: E4.

## PO3: Function and Method Return Recording Is Preserved

For every function or method object description with return annotation `R`:

Precondition:

- `objtype not in {"class", "exception"}`
- `callable(obj)` and `inspect.signature(obj)` returns return annotation `R`

Postcondition:

- `"return"` is present in `annotations[name]`
- later description-mode merge remains able to create a function or method
  `rtype` field according to existing configuration rules

Public evidence: E3.

## PO4: Merge Only Emits RType From Recorded Return

For every Python-domain object description processed by `merge_typehints()`:

Precondition:

- `autodoc_typehints in {"both", "description"}`
- `annotations[fullname]` is the map recorded for the object

Postcondition:

- `modify_field_list()` emits `rtype` only if `"return" in annotations`
- `augment_descriptions_with_types()` emits `rtype` only if
  `"return" in annotations`

Implementation evidence: both merge helpers branch on the presence of the
`"return"` key before creating an `rtype` field.

## Adequacy Check

PO1 plus PO4 exactly covers the issue path: `autoclass` with a constructor
return annotation under description mode. PO3 prevents the proof from becoming
too strong by preserving function and method behavior. PO2 covers the
class-like exception sibling that shares `ClassDocumenter` behavior.

No loop, recursion, arithmetic, ordering, or termination obligations are
present in this unit.
