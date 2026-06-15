requires "mini-python-enum-serializer.k"

module ENUM-SERIALIZER-SPEC
  imports MINI-PYTHON-ENUM-SERIALIZER
  imports STRING
  imports INT

  // SPEC-PROVENANCE:
  // - from_prompt: "Migrations uses value of enum object instead of its name."
  //   => the serialized expression must be a class name lookup by member name.
  // - from_prompt: "It should be: ... Status['GOOD']"
  //   => the output form is bracket lookup with the stable enum member name.
  // - from_hint: "we should use a name property"
  //   => the name field N, not the value field V, is the expression operand.
  // - from_code: EnumSerializer returns a pair of serialized code and imports.
  claim
    <k> serializeEnum(enumMember(M:String, C:String, N:String, V:Value))
      => serializeResult(
           M +String "." +String C +String "[" +String reprString(N) +String "]",
           importSet("import " +String M)
         )
    </k>
    requires lengthString(N) >=Int 1
    [all-path]
endmodule
