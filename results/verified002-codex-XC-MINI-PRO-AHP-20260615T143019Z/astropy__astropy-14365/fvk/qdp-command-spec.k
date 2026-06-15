// Constructed FVK artifact, not machine-checked in this session.

requires "mini-qdp.k"

module QDP-COMMAND-SPEC
  imports MINI-QDP

  // SPEC-PROVENANCE:
  // - from_prompt: "QDP itself is not case sensitive and ... can use
  //   'read serr 1 2'" => supported QDP error commands are recognized
  //   independently of ASCII case.
  // - from_prompt: "The following qdp file should read into a Table with
  //   errors, rather than crashing" => command classification must not produce
  //   the unrecognized-line error for lowercase READ SERR.
  // - from_code: _get_tables_from_qdp_file already normalizes command[1] with
  //   .lower(), so the classifier is the changed proof point.
  claim [LINE-TYPE-CASE-INSENSITIVE-READ-ERR]:
    <k> lineType(readErr(R:String, E:String, CS:Cols)) => command ... </k>
    requires ciEq(R, "read")
     andBool errWord(E)
     andBool nonEmptyCols(CS)
    [all-path]

  // Concrete issue witness: "read serr 1 2".
  claim [LINE-TYPE-LOWERCASE-SERR-WITNESS]:
    <k> lineType(readErr("read", "serr", 1 2 .Cols)) => command ... </k>
    requires ciEq("read", "read")
     andBool ciEq("serr", "serr")
    [all-path]

  // Existing uppercase behavior is preserved.
  claim [LINE-TYPE-UPPERCASE-SERR-FRAME]:
    <k> lineType(readErr("READ", "SERR", 1 .Cols)) => command ... </k>
    requires ciEq("READ", "read")
     andBool ciEq("SERR", "serr")
    [all-path]

  claim [LINE-TYPE-MIXEDCASE-TERR]:
    <k> lineType(readErr("Read", "Terr", 3 .Cols)) => command ... </k>
    requires ciEq("Read", "read")
     andBool ciEq("Terr", "terr")
    [all-path]

  // Downstream err-spec construction continues to receive the canonical keys
  // consumed by _interpret_err_lines.
  claim [ERR-SPEC-KEY-SERR-NORMALIZED]:
    <k> errKey(readErr(R:String, E:String, CS:Cols)) => "serr" ... </k>
    requires ciEq(R, "read")
     andBool ciEq(E, "serr")
     andBool nonEmptyCols(CS)
    [all-path]

  claim [ERR-SPEC-KEY-TERR-NORMALIZED]:
    <k> errKey(readErr(R:String, E:String, CS:Cols)) => "terr" ... </k>
    requires ciEq(R, "read")
     andBool ciEq(E, "terr")
     andBool nonEmptyCols(CS)
    [all-path]
endmodule
