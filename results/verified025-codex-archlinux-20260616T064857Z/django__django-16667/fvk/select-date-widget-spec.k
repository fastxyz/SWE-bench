requires "mini-python.k"

module SELECT-DATE-WIDGET-SPEC
  imports MINI-PYTHON
  imports BOOL
  imports STRING

  // SPEC-PROVENANCE:
  // - from_public_tests: all blank components return None.
  // - from_code: this is the first branch in value_from_datadict().
  claim
    <k> valueFromDatadict(present(""), present(""), present(""), LEGACY, FMT)
      => noneResult()
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: missing components fall back to data.get(name).
  // - from_public_api: preserve the existing caller protocol and return category.
  claim
    <k> valueFromDatadict(absent(), M, D, LEGACY, FMT)
      => LEGACY
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: missing components fall back to data.get(name).
  // - from_public_api: preserve the existing caller protocol and return category.
  claim
    <k> valueFromDatadict(Y, absent(), D, LEGACY, FMT)
      => LEGACY
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: missing components fall back to data.get(name).
  // - from_public_api: preserve the existing caller protocol and return category.
  claim
    <k> valueFromDatadict(Y, M, absent(), LEGACY, FMT)
      => LEGACY
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: valid complete triples return formatted dates.
  // - from_code: input format lookup and strftime are unchanged.
  claim
    <k> valueFromDatadict(present(Y), present(M), present(D), LEGACY, FMT)
      => formattedDate(Y, M, D, FMT)
    </k>
    requires notBool (Y ==String "" andBool M ==String "" andBool D ==String "")
     andBool validComplete(Y, M, D)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_comment: invalid complete triples return pseudo-ISO strings.
  // - from_public_tests: blank partial complete triples preserve pseudo-ISO output.
  claim
    <k> valueFromDatadict(present(Y), present(M), present(D), LEGACY, FMT)
      => pseudoDate(Y, M, D)
    </k>
    requires notBool (Y ==String "" andBool M ==String "" andBool D ==String "")
     andBool valueErrorComplete(Y, M, D)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: oversized user-controlled components previously raised OverflowError.
  // - from_prompt: the crash occurs during form.is_valid() and must not escape.
  // - from_comment: invalid complete triples use the pseudo-ISO representation.
  claim
    <k> valueFromDatadict(present(Y), present(M), present(D), LEGACY, FMT)
      => pseudoDate(Y, M, D)
    </k>
    requires notBool (Y ==String "" andBool M ==String "" andBool D ==String "")
     andBool overflowComplete(Y, M, D)
    [all-path]
endmodule

