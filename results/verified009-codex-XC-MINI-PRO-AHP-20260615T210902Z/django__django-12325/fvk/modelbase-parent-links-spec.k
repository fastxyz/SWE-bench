requires "mini-django-parent-links.k"

module MODELBASE-PARENT-LINKS-SPEC
  imports MINI-DJANGO-PARENT-LINKS
  imports MAP-SYMBOLIC
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - from_prompt: "we have explicit parent_link marker" => ParentLink is the
  //   authoritative signal for a user-declared inheritance link.
  // - from_docs: "set parent_link=True ... to indicate that your field is the
  //   link back to the parent class" => ordinary OneToOneField entries do not
  //   claim _meta.parents.
  claim
    <k> collect(field(1, 10, true, true) ; field(2, 10, true, false) ; .Fields)
     => (10 |-> 1)
     ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "First issue is that order seems to matter? ... It
  //   shouldn't" => ordinary fields before the explicit parent link must not
  //   prevent that explicit parent link from being selected.
  claim
    <k> collect(field(2, 10, true, false) ; field(1, 10, true, true) ; .Fields)
     => (10 |-> 1)
     ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "some_unrelated_document = OneToOneField(Document,
  //   related_name='something'...) Produces the same error" => a standalone
  //   ordinary OneToOneField to the parent must not be a parent-link entry.
  // - from_docs: "Django will automatically create a OneToOneField linking
  //   your child class back to any non-abstract parent models" => absence of a
  //   declared parent_link entry leaves the parent map empty for auto-creation.
  claim
    <k> collect(field(2, 10, true, false) ; .Fields)
     => .Map
     ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: ModelBase scans OneToOneField instances only.
  // - from_intent: non-OneToOne fields must not affect the parent-link map.
  claim
    <k> collect(field(3, 10, false, true) ; .Fields)
     => .Map
     ... </k>
    [all-path]
endmodule
