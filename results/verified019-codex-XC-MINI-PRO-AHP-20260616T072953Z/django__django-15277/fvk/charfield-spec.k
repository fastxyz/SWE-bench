requires "mini-python-charfield.k"

module CHARFIELD-SPEC
  imports MINI-PYTHON-CHARFIELD

  // SPEC-PROVENANCE:
  // - from_prompt: "MaxLengthValidator ... cannot work and must be demonstrably extraneous"
  //   => no MaxLengthValidator(None) for an unbounded CharField.
  // - from_prompt: "if self.max_length is not None"
  //   => the append is skipped exactly when max_length is None.
  claim
    <k> charField(none, VS:Validators) => field(none, VS) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "if self.max_length is not None"
  //   => bounded/non-None max_length still creates the automatic validator.
  // - from_code: BinaryField.__init__ uses the same guard shape.
  claim
    <k> charField(some(L:Limit), VS:Validators)
        => field(some(L), VS ; MaxLengthValidator(some(L))) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "Value('test')" eventually returns "fields.CharField()".
  // - from_code: Value._resolve_output_field() returns fields.CharField() for str.
  claim
    <k> resolveValueString => field(none, .Validators) </k>
    [all-path]
endmodule
