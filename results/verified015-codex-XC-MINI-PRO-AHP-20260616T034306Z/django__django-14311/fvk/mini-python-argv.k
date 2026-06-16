module MINI-PYTHON-ARGV-SYNTAX
  imports STRING-SYNTAX
  imports LIST-SYNTAX

  syntax Spec ::= noSpec
                | moduleSpec(String)
                | packageMainSpec(String)
                | emptyMainSpec

  syntax PathState ::= scriptExists
                     | exeEntry(String)
                     | scriptEntry(String)
                     | missingScript(String)

  syntax Result ::= args(List)
                  | runtimeError(String)

  syntax Command ::= childArgs(List, List, List, Spec, PathState)
                   | fallback(List, List, List, PathState)

  syntax KResult ::= Result
endmodule

module MINI-PYTHON-ARGV
  imports MINI-PYTHON-ARGV-SYNTAX
  imports STRING
  imports LIST

  configuration <k> $PGM:Command </k>

  // Ordinary module specs, including dotted module files and names such as
  // foo.my__main__, restart with the full spec name.
  rule <k> childArgs(BASE:List, TAIL:List, _FULL:List, moduleSpec(NAME:String), _PATH:PathState)
        => args(BASE ListItem("-m") ListItem(NAME) TAIL) ... </k>
    requires NAME =/=String ""

  // Exact __main__ or dotted .__main__ package specs restart with the parent.
  rule <k> childArgs(BASE:List, TAIL:List, _FULL:List, packageMainSpec(PARENT:String), _PATH:PathState)
        => args(BASE ListItem("-m") ListItem(PARENT) TAIL) ... </k>
    requires PARENT =/=String ""

  rule <k> childArgs(BASE:List, TAIL:List, FULL:List, noSpec, PATH:PathState)
        => fallback(BASE, TAIL, FULL, PATH) ... </k>

  rule <k> childArgs(BASE:List, TAIL:List, FULL:List, emptyMainSpec, PATH:PathState)
        => fallback(BASE, TAIL, FULL, PATH) ... </k>

  rule <k> fallback(BASE:List, _TAIL:List, FULL:List, scriptExists)
        => args(BASE FULL) ... </k>

  rule <k> fallback(_BASE:List, TAIL:List, _FULL:List, exeEntry(EXE:String))
        => args(ListItem(EXE) TAIL) ... </k>

  rule <k> fallback(BASE:List, TAIL:List, _FULL:List, scriptEntry(SCRIPT:String))
        => args(BASE ListItem(SCRIPT) TAIL) ... </k>

  rule <k> fallback(_BASE:List, _TAIL:List, _FULL:List, missingScript(ARG0:String))
        => runtimeError(ARG0) ... </k>
endmodule
