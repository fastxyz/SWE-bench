# FVK Proof Obligations

Status: constructed, not machine-checked.

## Domain

The verified domain is the public issue domain:

- a constructed `ManyToManyRel`;
- `self.through_fields` is `None` or a sequence accepted by Django's
  `through_fields` contract, especially a list or tuple of field-name strings;
- all other identity elements satisfy Django's existing relation-identity
  assumptions, including the existing `make_hashable(self.limit_choices_to)`
  normalization in `ForeignObjectRel.identity`.

## Obligations

### PO-1: Hashability for list-valued `through_fields`

For `through_fields = ["child", "parent"]`,
`hash(ManyToManyRel.identity)` must not fail because of the list.

Formal core:

```k
claim
  <k>
    hashable(
      manyToManyIdentity(
        atom("field"), atom("model"), none, none, none,
        bool(false), atom("on_delete"), bool(false), bool(true),
        atom("through"), list(ListItem(str("child")) ListItem(str("parent"))),
        bool(true)
      )
    )
  => true
  </k>
```

Trace: F-001, F-002.

### PO-2: Identity normalizes the `through_fields` element at the point of extension

`ManyToManyRel.identity` must append
`make_hashable(self.through_fields)`, not `self.through_fields`, to the base
identity.

Formal core:

```k
rule manyToManyIdentity(FIELD, MODEL, RELATED_NAME, RELATED_QUERY_NAME, LIMIT_CHOICES_TO,
                        PARENT_LINK, ON_DELETE, SYMMETRICAL, MULTIPLE,
                        THROUGH, THROUGH_FIELDS, DB_CONSTRAINT)
  => tuple(
       ListItem(FIELD)
       ListItem(MODEL)
       ListItem(RELATED_NAME)
       ListItem(RELATED_QUERY_NAME)
       ListItem(makeHashable(LIMIT_CHOICES_TO))
       ListItem(PARENT_LINK)
       ListItem(ON_DELETE)
       ListItem(SYMMETRICAL)
       ListItem(MULTIPLE)
       ListItem(THROUGH)
       ListItem(makeHashable(THROUGH_FIELDS))
       ListItem(DB_CONSTRAINT)
     )
```

Trace: F-001, F-002, F-004.

### PO-3: Identity evaluation does not mutate `self.through_fields`

The identity property must compute a normalized contribution without writing
back to `self.through_fields`.

Reason:

`related.py` validates and resolves `through_fields` by length checks, indexing,
and slicing. The public issue asks for identity hashability, not stored attribute
conversion.

Trace: F-003.

### PO-4: The repair remains local to `ManyToManyRel.identity`

The proof must not require changing `ForeignObjectRel.__hash__()` or unrelated
relation classes.

Reason:

The base relation already normalizes one known unhashable identity component
locally. The public issue identifies the missing local normalization for
`through_fields`.

Trace: F-004.

### PO-5: Equality remains consistent with hashability

If two `ManyToManyRel` objects differ only by spelling the same
`through_fields` sequence as a list versus a tuple, their normalized identity
contributions are equal.

Formal core:

```k
claim
  <k>
    manyToManyIdentity(
      atom("field"), atom("model"), none, none, none,
      bool(false), atom("on_delete"), bool(false), bool(true),
      atom("through"), list(ListItem(str("child")) ListItem(str("parent"))),
      bool(true)
    )
  => manyToManyIdentity(
      atom("field"), atom("model"), none, none, none,
      bool(false), atom("on_delete"), bool(false), bool(true),
      atom("through"), tuple(ListItem(str("child")) ListItem(str("parent"))),
      bool(true)
    )
  </k>
```

Trace: F-002.

### PO-6: No machine-check or test result is claimed

The proof artifacts must include exact commands for later verification, but this
benchmark phase must not execute them.

Commands, intentionally not run:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/many-to-many-rel-spec.k
kprove fvk/many-to-many-rel-spec.k --backend haskell
```

Trace: F-005.
