requires "mini-python.k"

module MORSE-SPEC
  imports MINI-PYTHON-MORSE
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - from_prompt: "The correct mapping is `\".----\": \"1\"`."
  // - from_prompt: "`\"----\": \"1\"`" is incorrect legacy behavior.
  claim [MORSE-TABLE-ONE]:
    <k> decodeDefault(".----") => "1" </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: `char_morse = {v: k for k, v in morse_char.items()}`
  // - from_prompt: default encoding for "1" must use `.----`.
  claim [MORSE-INVERSE-ONE]:
    <k> lookup(digitCharMorse(), "1") => ".----" </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "Morse encoding for \"1\" is not correct."
  claim [ENCODE-ONE]:
    <k> encodeDefault("1") => ".----" </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: corrected source mapping `.----` decodes to "1".
  claim [DECODE-ONE]:
    <k> decodeDefault(".----") => "1" </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_default_domain: standard Morse digit family.
  claim [DIGIT-FAMILY]:
    <k> digitMorseChar()
      => "-----" |-> "0"
         ".----" |-> "1"
         "..---" |-> "2"
         "...--" |-> "3"
         "....-" |-> "4"
         "....." |-> "5"
         "-...." |-> "6"
         "--..." |-> "7"
         "---.." |-> "8"
         "----." |-> "9"
         .Map
    </k>
    [all-path]
endmodule

