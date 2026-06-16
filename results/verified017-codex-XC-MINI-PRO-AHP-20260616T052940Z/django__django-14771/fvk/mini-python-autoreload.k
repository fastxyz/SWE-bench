module MINI-PYTHON-AUTORELOAD-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax XVal ::= "flag"
                | "val" "(" String ")"

  syntax Warns ::= ".Warns"
                 | "warn" "(" String "," Warns ")"

  syntax XOpts ::= ".XOpts"
                 | "xopt" "(" String "," XVal "," XOpts ")"

  syntax Args ::= ".Args"
                | "arg" "(" String "," Args ")"

  syntax MainKind ::= "asModule" "(" String ")"
                    | "asScript" "(" String ")"
                    | "asScriptEntrypoint" "(" String ")"
                    | "asExeEntrypoint" "(" String ")"
                    | "asMissingScript" "(" String ")"

  syntax Args ::= "append" "(" Args "," Args ")" [function]
                | "warnArgs" "(" Warns ")" [function]
                | "xArgs" "(" Bool "," XOpts ")" [function]
                | "moduleArgs" "(" String "," Args ")" [function]
                | "scriptArgs" "(" String "," Args ")" [function]
                | "childArgs" "(" String "," Warns "," Bool "," XOpts "," MainKind "," Args ")" [function]

  syntax String ::= "formatX" "(" String "," XVal ")" [function]

  syntax KResult ::= Args
endmodule

module MINI-PYTHON-AUTORELOAD
  imports MINI-PYTHON-AUTORELOAD-SYNTAX
  imports BOOL
  imports STRING

  configuration <k> $PGM:Args </k>

  rule append(.Args, AS:Args) => AS
  rule append(arg(A:String, AS:Args), BS:Args) => arg(A, append(AS, BS))

  rule warnArgs(.Warns) => .Args
  rule warnArgs(warn(W:String, WS:Warns)) => arg("-W" +String W, warnArgs(WS))

  rule formatX(KEY:String, flag) => "-X" +String KEY
  rule formatX(KEY:String, val(V:String)) => "-X" +String KEY +String "=" +String V

  rule xArgs(false, XS:XOpts) => .Args
  rule xArgs(true, .XOpts) => .Args
  rule xArgs(true, xopt(KEY:String, VALUE:XVal, REST:XOpts))
    => arg(formatX(KEY, VALUE), xArgs(true, REST))

  rule moduleArgs(NAME:String, USER:Args) => arg("-m", arg(NAME, USER))
  rule scriptArgs(PATH:String, USER:Args) => arg(PATH, USER)

  rule childArgs(EXE:String, WARNS:Warns, HASX:Bool, XOPTS:XOpts, asModule(NAME:String), USER:Args)
    => arg(EXE, append(warnArgs(WARNS), append(xArgs(HASX, XOPTS), moduleArgs(NAME, USER))))

  rule childArgs(EXE:String, WARNS:Warns, HASX:Bool, XOPTS:XOpts, asScript(PATH:String), USER:Args)
    => arg(EXE, append(warnArgs(WARNS), append(xArgs(HASX, XOPTS), scriptArgs(PATH, USER))))

  rule childArgs(EXE:String, WARNS:Warns, HASX:Bool, XOPTS:XOpts, asScriptEntrypoint(PATH:String), USER:Args)
    => arg(EXE, append(warnArgs(WARNS), append(xArgs(HASX, XOPTS), scriptArgs(PATH, USER))))

  rule childArgs(EXE:String, WARNS:Warns, HASX:Bool, XOPTS:XOpts, asExeEntrypoint(PATH:String), USER:Args)
    => arg(PATH, USER)

  rule childArgs(EXE:String, WARNS:Warns, HASX:Bool, XOPTS:XOpts, asMissingScript(PATH:String), USER:Args)
    => arg("RuntimeError:Script " +String PATH +String " does not exist.", .Args)
endmodule
