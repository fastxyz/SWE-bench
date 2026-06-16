requires "mini-era001-script-scan.k"

module ERA001-SCRIPT-SCAN-SPEC
  imports MINI-ERA001-SCRIPT-SCAN

  // SPEC-PROVENANCE:
  // - from_prompt: "false positive inside inline script metadata with trailing additional comment"
  //   => valid metadata comments through the closing delimiter are not ERA001 candidates.
  // - from_code: ruff_python_ast::script identifies the last content line equal to "///" as the
  //   closing pragma before non-metadata content.
  // - from_code: commented_out_code advances the comment iterator while comment.start < end_offset.

  claim <k> scanFrom(line(S:Int, E:Int, content("///")) ;; LS:Lines, LAST:MaybeInt)
              => scanFrom(LS, someInt(E)) </k>
    [all-path]

  claim <k> scanFrom(line(S:Int, E:Int, content(C:String)) ;; LS:Lines, LAST:MaybeInt)
              => scanFrom(LS, LAST) </k>
    requires C =/=String "///"
    [all-path]

  claim <k> scanFrom(line(S:Int, E:Int, invalidContent()) ;; LS:Lines, someInt(CLOSE:Int))
              => someInt(CLOSE) </k>
    [all-path]

  claim <k> scanFrom(.Lines, someInt(CLOSE:Int)) => someInt(CLOSE) </k>
    [all-path]

  claim <k> scanFrom(.Lines, noneInt()) => noneInt() </k>
    [all-path]

  claim <k> skipBefore(CLOSE:Int, line(S:Int, E:Int, C:Content) ;; LS:Lines)
              => skipBefore(CLOSE, LS) </k>
    requires S <Int CLOSE
    [all-path]

  claim <k> skipBefore(CLOSE:Int, line(S:Int, E:Int, C:Content) ;; LS:Lines)
              => line(S, E, C) ;; LS </k>
    requires S >=Int CLOSE
    [all-path]
endmodule
