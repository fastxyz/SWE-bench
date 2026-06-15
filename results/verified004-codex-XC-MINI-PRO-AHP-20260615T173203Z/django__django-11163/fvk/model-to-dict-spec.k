requires "mini-python.k"

module MODEL-TO-DICT-SPEC
  imports MINI-PYTHON-MODEL-TO-DICT

  // SPEC-PROVENANCE:
  // - from_prompt: "model_to_dict() should return an empty dict for an empty list of fields."
  // - from_docstring: "`fields` is an optional list... If provided, return only the named."
  // - from_docstring: "`exclude` ... exclude the named ... even if they are listed in `fields`."
  // - from_hint: skipped field values should not be touched.
  // - from_code: model_to_dict iterates a finite model metadata field sequence.
  claim
    <k> model_to_dict(FIELDS:FieldsOpt, EXCLUDE:ExcludeOpt, FS:FieldSeq)
      => expectedResult(FS, FIELDS, EXCLUDE)
    </k>
    [all-path, label(MODEL-TO-DICT-GENERAL)]

  // SPEC-PROVENANCE:
  // - helper circularity for the field loop used by MODEL-TO-DICT-GENERAL.
  // - DATA and READS are accumulators; each step processes one field then recurs.
  claim
    <k> filterFields(FIELDS:FieldsOpt, EXCLUDE:ExcludeOpt, FS:FieldSeq, DATA:Map, READS:NameList)
      => expectedFrom(FS, FIELDS, EXCLUDE, DATA, READS)
    </k>
    [all-path, label(FILTER-FIELDS-CIRCULARITY)]

  // SPEC-PROVENANCE:
  // - from_prompt: fields=[] means no fields were requested.
  // - from_docstring: an explicitly provided fields list restricts output to its names.
  claim
    <k> model_to_dict(someFields(.Names), EXCLUDE:ExcludeOpt, FS:FieldSeq)
      => result(.Map, .Names)
    </k>
    [all-path, label(MODEL-TO-DICT-EMPTY-FIELDS)]
endmodule
