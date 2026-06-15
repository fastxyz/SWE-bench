requires "mini-python-enum.k"

module CHOICES-STR-SPEC
  imports MINI-PYTHON-ENUM

  // SPEC-PROVENANCE:
  // - from_prompt: "The value of a TextChoices/IntegerChoices field has a differing type"
  //   => cover both string-valued and integer-valued enum members.
  // - from_prompt: "self.assertEqual(str(my_object.my_str_value), \"first\")"
  //   => created enum member field values must stringify to the concrete value.
  // - from_docs: enum members expose ".value" as the concrete data type value.
  claim <k> CreateThenStr(Choice(NAME:String, V:Value)) => valueText(V) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: retrieved instances stringify to "first".
  // - from_hint: retrieved __dict__ stores the primitive value.
  claim <k> RetrieveThenStr(V:Value) => valueText(V) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: created and retrieved field values must have matching external API output.
  claim <k> CreatedRetrievedTexts(Choice(NAME:String, V:Value)) => pair(valueText(V), valueText(V)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: concrete failing example expects "first".
  claim <k> CreateThenStr(Choice("FIRST_CHOICE", SVal("first"))) => text("first") </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: repr(member) remains enum-style; V1 does not modify __repr__.
  claim <k> ReprOf(Choice(NAME:String, V:Value)) => enumText(NAME) </k>
    [all-path]
endmodule
