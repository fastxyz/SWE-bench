requires "mini-autodoc-typehints.k"

module AUTODOC-TYPEHINTS-SPEC
  imports MINI-AUTODOC-TYPEHINTS
  imports BOOL
  imports STRING

  // SPEC-PROVENANCE:
  // - prompt: "I expected there to be no return type listed for the class."
  //   => class object descriptions must not receive an rtype field from
  //      constructor return annotations.
  // - code: merge_typehints adds rtype only when annotations[fullname] contains
  //   key "return"; this model represents that as recordedReturn => rtypeEmitted.
  claim <k>
          recordTypehints(class,
            signature(paramAnn(width, "int") paramAnn(height, "int") .ParamAnns,
                      returnType("None")))
          ~> mergeTypehints
          => .K
        </k>
        <recordedParams>
          .ParamAnns
          => paramAnn(width, "int") paramAnn(height, "int") .ParamAnns
        </recordedParams>
        <recordedReturn> false => false </recordedReturn>
        <rtypeEmitted> false => false </rtypeEmitted>
    [all-path]

  // SPEC-PROVENANCE:
  // - docs: py:exception describes an exception class.
  // - code: ExceptionDocumenter inherits ClassDocumenter behavior.
  claim <k>
          recordTypehints(exception,
            signature(paramAnn(message, "str") .ParamAnns, returnType("None")))
          ~> mergeTypehints
          => .K
        </k>
        <recordedParams>
          .ParamAnns => paramAnn(message, "str") .ParamAnns
        </recordedParams>
        <recordedReturn> false => false </recordedReturn>
        <rtypeEmitted> false => false </rtypeEmitted>
    [all-path]

  // SPEC-PROVENANCE:
  // - docs: autodoc_typehints 'description' shows typehints as content of
  //   "the function or method".
  // - frame condition: function/method rtype behavior is preserved.
  claim <k>
          recordTypehints(function,
            signature(paramAnn(a, "int") .ParamAnns, returnType("int")))
          ~> mergeTypehints
          => .K
        </k>
        <recordedParams>
          .ParamAnns => paramAnn(a, "int") .ParamAnns
        </recordedParams>
        <recordedReturn> false => true </recordedReturn>
        <rtypeEmitted> false => true </rtypeEmitted>
    [all-path]
endmodule
