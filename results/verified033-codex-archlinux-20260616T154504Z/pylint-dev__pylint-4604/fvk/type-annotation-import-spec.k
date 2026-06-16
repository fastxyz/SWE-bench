requires "mini-pylint-variables.k"

module TYPE-ANNOTATION-IMPORT-SPEC
  imports MINI-PYLINT-VARIABLES

  // SPEC-PROVENANCE:
  // CLAIM: ATTR-ABC-NAMES
  // - from_prompt: "X = ...  # type: abc.ABC" => abc must be collected.
  claim <k> collect(Attr(Name("abc"), "ABC")) => NAMES </k>
    ensures ("abc" in NAMES) andBool ("abc.ABC" in NAMES)

  // SPEC-PROVENANCE:
  // CLAIM: REPRO-ABC
  // - from_prompt: "unused-import should not be emitted" for import abc.
  claim <k> isTypeUsed("abc", noAlias, collect(Attr(Name("abc"), "ABC"))) => true </k>

  // SPEC-PROVENANCE:
  // CLAIM: NAME-ABC
  // - from_prompt: "Y = ...  # type: ABC" => existing simple-name case remains used.
  claim <k> collect(Name("ABC")) => NAMES </k>
    ensures "ABC" in NAMES

  // SPEC-PROVENANCE:
  // CLAIM: TYPING-NESTED-ABC
  // - from_prompt: "module used in a type comment" => nested use under typing is still a use.
  claim <k> collect(Sub(Attr(Name("typing"), "Optional"), Attr(Name("abc"), "ABC"))) => NAMES </k>
    ensures ("typing" in NAMES) andBool ("abc" in NAMES)

  // SPEC-PROVENANCE:
  // CLAIM: DOTTED-IMPORT
  // - from_code: _fix_dot_imports can compare imported_name "xml.etree".
  claim <k> collect(Attr(Attr(Name("xml"), "etree"), "ElementTree")) => NAMES </k>
    ensures ("xml" in NAMES) andBool ("xml.etree" in NAMES)

  // SPEC-PROVENANCE:
  // CLAIM: SUPPRESS-IMPORT
  // - from_code: _check_imports suppresses when imported_name or as_name is collected.
  claim <k> isTypeUsed(IMPORTED, alias(ALIAS), NAMES) => true </k>
    requires (IMPORTED in NAMES) orBool (ALIAS in NAMES)

  // SPEC-PROVENANCE:
  // CLAIM: UNMATCHED-IMPORT-FRAME
  // - frame: unmatched imports are not newly suppressed by this fix.
  claim <k> isTypeUsed(IMPORTED, alias(ALIAS), NAMES) => false </k>
    requires notBool (IMPORTED in NAMES) andBool notBool (ALIAS in NAMES)
endmodule
