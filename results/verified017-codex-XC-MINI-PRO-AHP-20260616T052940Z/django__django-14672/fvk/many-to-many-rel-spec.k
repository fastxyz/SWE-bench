// Constructed, not machine-checked.
// K-style claims for django__django-14672.

requires "mini-python.k"

module MANY-TO-MANY-REL-SPEC
  imports MINI-M2M-REL

  // SPEC-PROVENANCE:
  // - from_prompt: "through_fields can be a list" and "Add missing make_hashable call"
  //   => list-valued through_fields must be normalized in ManyToManyRel.identity.
  // - from_code: ForeignObjectRel.__hash__ returns hash(self.identity)
  //   => every value in identity must be hashable on the hash path.
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

  // SPEC-PROVENANCE:
  // - from_prompt: "identity property has been added ... to compare them"
  //   => semantically equal through_fields names should contribute the same identity.
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

  // SPEC-PROVENANCE:
  // - from_code: related.py validates and resolves self.remote_field.through_fields
  //   by len(), indexing, and slicing.
  // - compatibility: the stored attribute must not be mutated by identity evaluation.
  claim
    <k>
      makeHashable(list(ListItem(str("child")) ListItem(str("parent"))))
    => tuple(ListItem(str("child")) ListItem(str("parent")))
    </k>
endmodule
