requires "mini-floatformat.k"

module FLOATFORMAT-SPEC
  imports MINI-FLOATFORMAT

  // SPEC-PROVENANCE:
  // - from_prompt: "Decimal numbers are converted to float instead." =>
  //   Decimal input must not route through float conversion.
  // - from_docs_or_tests: Decimal inputs are public in-domain values.
  // - from_code: V1 `isinstance(text, Decimal)` branch assigns `d = text`.
  claim [DECIMAL-PRESERVE]:
    <k> floatformat(decimal(D:Dec), places(P:Int)) => render(D, P) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: `Decimal('42.12345678901234567890')` with
  //   `floatformat:20` must not produce `42.12345678901234400000`.
  // - from_docs_or_tests: positive integer argument displays exactly that many
  //   decimal places.
  claim [ISSUE-DECIMAL-20]:
    <k> floatformat(decimal(dec(0, 4212345678901234567890, 20)), places(20))
      => rendered("42.12345678901234567890")
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs_or_tests: existing float/string/grouping behavior is public.
  // - from_prompt: the issue is Decimal-specific.
  // - from_code: V1 leaves the non-Decimal branch unchanged.
  claim [NONDECIMAL-FRAME]:
    <k> floatformat(nondecimal(R:String), places(P:Int))
      => render(decimalFromRepr(R), P)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs_or_tests: invalid argument behavior returns the input display
  //   for public numeric examples.
  // - from_code: V1 uses `str(text)` as `input_val` for Decimal.
  claim [INVALID-ARG-DECIMAL-DISPLAY]:
    <k> floatformat(decimal(D:Dec), invalidArg(A:String))
      => original(decimal(D))
    </k>
    [all-path]
endmodule
