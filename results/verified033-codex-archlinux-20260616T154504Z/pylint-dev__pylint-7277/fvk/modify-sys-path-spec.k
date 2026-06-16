requires "mini-python-syspath.k"

module MODIFY-SYS-PATH-SPEC
  imports MINI-PYTHON-SYSPATH
  imports BOOL
  imports INT
  imports STRING
  imports LIST

  // SPEC-PROVENANCE:
  // - E1/E2/E3: the first path is caller-owned unless it is "", ".", or cwd.
  claim [FIRST-NONCWD-NOEDGE]:
    <k> modifySysPath(ListItem(FIRST:String) REST:List, noEdge, CWD:String)
        => ListItem(FIRST) REST ... </k>
    requires CWD =/=String "" andBool CWD =/=String "."
     andBool notBool isCwdPath(FIRST, CWD)
    [all-path]

  // SPEC-PROVENANCE:
  // - E3/E4: a CWD-like first path is removable.
  claim [FIRST-CWD-NOEDGE]:
    <k> modifySysPath(ListItem(FIRST:String) REST:List, noEdge, CWD:String)
        => REST ... </k>
    requires CWD =/=String "" andBool CWD =/=String "."
     andBool isCwdPath(FIRST, CWD)
    [all-path]

  // SPEC-PROVENANCE:
  // - Domain safety side condition: helper checks never blindly pop from empty.
  claim [EMPTY-PATH]:
    <k> modifySysPath(.List, noEdge, CWD:String) => .List ... </k>
    requires CWD =/=String "" andBool CWD =/=String "."
    [all-path]

  // SPEC-PROVENANCE:
  // - E2/E5: leading PYTHONPATH cleanup must not remove a non-CWD first path.
  claim [FIRST-NONCWD-LEADING]:
    <k> modifySysPath(ListItem(FIRST:String) ListItem(SECOND:String) REST:List,
                      leadingImplicit, CWD:String)
        => ListItem(FIRST) REST ... </k>
    requires CWD =/=String "" andBool CWD =/=String "."
     andBool notBool isCwdPath(FIRST, CWD)
     andBool isCwdPath(SECOND, CWD)
    [all-path]

  // SPEC-PROVENANCE:
  // - E4/E5: normal module execution removes first CWD and leading implicit CWD.
  claim [FIRST-CWD-LEADING]:
    <k> modifySysPath(ListItem(FIRST:String) ListItem(SECOND:String) REST:List,
                      leadingImplicit, CWD:String)
        => REST ... </k>
    requires CWD =/=String "" andBool CWD =/=String "."
     andBool isCwdPath(FIRST, CWD)
     andBool isCwdPath(SECOND, CWD)
    [all-path]

  // SPEC-PROVENANCE:
  // - E2/E5: trailing PYTHONPATH cleanup must not remove a non-CWD first path.
  claim [FIRST-NONCWD-TRAILING]:
    <k> modifySysPath(ListItem(FIRST:String) ListItem(SECOND:String)
                      ListItem(THIRD:String) REST:List,
                      trailingImplicit, CWD:String)
        => ListItem(FIRST) ListItem(SECOND) REST ... </k>
    requires CWD =/=String "" andBool CWD =/=String "."
     andBool notBool isCwdPath(FIRST, CWD)
     andBool isCwdPath(THIRD, CWD)
    [all-path]

  // SPEC-PROVENANCE:
  // - E4/E5: normal module execution removes first CWD and trailing implicit CWD.
  claim [FIRST-CWD-TRAILING]:
    <k> modifySysPath(ListItem(FIRST:String) ListItem(SECOND:String)
                      ListItem(THIRD:String) REST:List,
                      trailingImplicit, CWD:String)
        => ListItem(SECOND) REST ... </k>
    requires CWD =/=String "" andBool CWD =/=String "."
     andBool isCwdPath(FIRST, CWD)
     andBool isCwdPath(THIRD, CWD)
    [all-path]

  // SPEC-PROVENANCE:
  // - E6: explicit cwd or "." in PYTHONPATH skips the extra colon cleanup.
  claim [EXPLICIT-LEADING]:
    <k> modifySysPath(ListItem(FIRST:String) REST:List, leadingExplicit, CWD:String)
        => modifySysPathValue(ListItem(FIRST) REST, noEdge, CWD) ... </k>
    requires CWD =/=String "" andBool CWD =/=String "."
    [all-path]

  // SPEC-PROVENANCE:
  // - E6: explicit cwd or "." in PYTHONPATH skips the extra colon cleanup.
  claim [EXPLICIT-TRAILING]:
    <k> modifySysPath(ListItem(FIRST:String) REST:List, trailingExplicit, CWD:String)
        => modifySysPathValue(ListItem(FIRST) REST, noEdge, CWD) ... </k>
    requires CWD =/=String "" andBool CWD =/=String "."
    [all-path]

  // SPEC-PROVENANCE:
  // - E7: later cwd entries are not globally purged.
  claim [LATER-CWD-PRESERVED]:
    <k> modifySysPath(ListItem(FIRST:String) ListItem(SECOND:String)
                      ListItem(CWD:String) REST:List,
                      noEdge, CWD)
        => ListItem(SECOND) ListItem(CWD) REST ... </k>
    requires CWD =/=String "" andBool CWD =/=String "."
     andBool isCwdPath(FIRST, CWD)
     andBool notBool isCwdPath(SECOND, CWD)
    [all-path]
endmodule
