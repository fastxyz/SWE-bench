# FVK Proof Obligations

Status: constructed, not machine-checked.

## Modeled State

The proof models a reduced class-member lookup state:

- `subject`: class-like object with finite MRO.
- `name`: member name.
- `attrgetter`: callable compatible with `getattr(obj, name, *default)`.
- `raw(cls, name)`: direct dictionary value for a class, if present.
- `AG(subject, name)`: result of the original attrgetter lookup.
- `is_cmp_prop(value)`: `isclassmethod(value) and isproperty(value.__func__)`.

Dictionary lookup failures for `cls.__dict__` are modeled as `absent`, matching
the helper's `except (AttributeError, KeyError, TypeError): continue`.

## Obligations

PO-1: Classmethod-property preservation

If the first class in `MRO(subject)` that defines `name` has raw value `R` and
`is_cmp_prop(R)`, then `get_class_member(subject, name, attrgetter)` returns
`R.__func__` and does not call `attrgetter(subject, name)`.

Intent trace: `SPEC.md` E1-E3, C1.

PO-2: Non-wrapper frame condition

If the first class in `MRO(subject)` that defines `name` has raw value `R` and
`not is_cmp_prop(R)`, then `get_class_member(subject, name, attrgetter)` returns
`attrgetter(subject, name)`.

If no class dictionary in the MRO defines `name`, the helper also returns
`attrgetter(subject, name)`.

Intent trace: `SPEC.md` E4, E7, C2.

PO-3: Override precedence

For any subclass `S` and base `B`, if `S.__dict__` defines `name`, then a
`classmethod(property(...))` in `B.__dict__` cannot be returned for `S.name`.

Intent trace: `SPEC.md` C3 and Python MRO default-domain convention.

PO-4: Enumeration consistency

Every class-member value retrieval in these audited paths uses
`get_class_member()`:

- `get_object_members()` enum branch;
- `get_object_members()` general `dir(subject)` branch;
- `get_class_members()` enum branch;
- `get_class_members()` general `dir(subject)` branch.

Intent trace: `SPEC.md` E1, E5, E6, C4.

PO-5: PropertyDocumenter import correction

If `PropertyDocumenter.import_object()` succeeds and `self.parent` is a class,
then after the method returns true, `self.object` equals
`get_class_member(self.parent, self.object_name, self.get_attr)`.

Intent trace: `SPEC.md` E3, C5.

PO-6: Existing property renderer adequacy

Given `self.object` is the wrapped property object, existing Sphinx behavior
classifies and renders it as a property:

- `inspect.isproperty(self.object)` is true;
- `getdoc(self.object, ...)` can obtain the property docstring;
- `inspect.isabstractmethod(self.object)` reflects abstract getter status;
- `self.object.fget` is available for return type extraction.

Intent trace: `SPEC.md` E3-E5, C6.

## Constructed K-Style Claims

These are specification sketches for later machine formalization. They are not
executed in this task.

```k
// CLAIM PO-1
claim
  <k> getClassMember(SUBJECT, NAME, ATTRGETTER) => PROP ... </k>
  <mro> SUBJECT |-> CLS REST </mro>
  <raw> CLS , NAME |-> classmethodProperty(PROP) </raw>
  requires firstDefines(SUBJECT, NAME, CLS)
```

```k
// CLAIM PO-2
claim
  <k> getClassMember(SUBJECT, NAME, ATTRGETTER)
       => attrget(ATTRGETTER, SUBJECT, NAME) ... </k>
  <mro> SUBJECT |-> CLS REST </mro>
  <raw> CLS , NAME |-> RAW </raw>
  requires firstDefines(SUBJECT, NAME, CLS)
   andBool notBool isClassmethodProperty(RAW)
```

```k
// CLAIM PO-3
claim
  <k> getClassMember(SUBCLASS, NAME, ATTRGETTER)
       => attrget(ATTRGETTER, SUBCLASS, NAME) ... </k>
  <mro> SUBCLASS |-> SUBCLASS BASE REST </mro>
  <raw> SUBCLASS , NAME |-> RAW_SUB </raw>
  <raw> BASE , NAME |-> classmethodProperty(BASE_PROP) </raw>
  requires notBool isClassmethodProperty(RAW_SUB)
```

```k
// CLAIM PO-5
claim
  <k> propertyDocumenterImport(DOC) => DOC' ... </k>
  <parent> DOC |-> PARENT </parent>
  <objectName> DOC |-> NAME </objectName>
  <class?> PARENT |-> true </class?>
  <object> DOC' |-> RESULT </object>
  requires RESULT ==K getClassMember(PARENT, NAME, docAttrgetter(DOC))
```

## Proof Dependencies

- Python MRO order is the default-domain ordering convention for class member
  lookup.
- `property.__doc__` and `property.__isabstractmethod__` are existing Python
  descriptor behavior relied on by Sphinx's current `PropertyDocumenter`.
- The proof is partial correctness: it proves returned values on completed
  helper/documenter paths, not termination of arbitrary user attrgetters.
