module MINI-PYTHON-PATHS-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax PathEntry ::= StrPath(String)
                     | PathObj(String)

  syntax Entries ::= ".Entries"
                   | Entry(PathEntry, Entries)

  syntax Strs ::= ".Strs"
                | SCons(String, Strs)

  syntax MaybeString ::= None
                       | Some(String)

  syntax Result ::= Ok(Strs)
                  | DuplicateError
                  | DefaultFixtureDirError(String)

  syntax String ::= fspath(PathEntry) [function]
  syntax Strs ::= fspaths(Entries) [function]
  syntax Bool ::= contains(String, Strs) [function]
                | hasDuplicate(Strs) [function]
                | hasIntersection(Strs, Strs) [function]
  syntax MaybeString ::= firstIntersection(Strs, Strs) [function]
  syntax Result ::= validate(Strs, Strs) [function]
                  | validateDefault(Strs, MaybeString) [function]
                  | fixtureDirs(Entries, Strs) [function]

  syntax KResult ::= String | Bool | Entries | Strs | MaybeString | Result
endmodule

module MINI-PYTHON-PATHS
  imports MINI-PYTHON-PATHS-SYNTAX
  imports STRING
  imports BOOL

  configuration <k> $PGM:Result </k>

  // Reduced semantics for the V1 line:
  // [os.fspath(fixture_dir) for fixture_dir in settings.FIXTURE_DIRS]
  rule fspath(StrPath(S:String)) => S
  rule fspath(PathObj(S:String)) => S

  rule fspaths(.Entries) => .Strs
  rule fspaths(Entry(E:PathEntry, ES:Entries)) => SCons(fspath(E), fspaths(ES))

  rule contains(S:String, .Strs) => false
  rule contains(S:String, SCons(S, REST:Strs)) => true
  rule contains(S1:String, SCons(S2:String, REST:Strs)) => contains(S1, REST)
    requires S1 =/=String S2

  rule hasDuplicate(.Strs) => false
  rule hasDuplicate(SCons(S:String, REST:Strs)) => true
    requires contains(S, REST) ==Bool true
  rule hasDuplicate(SCons(S:String, REST:Strs)) => hasDuplicate(REST)
    requires contains(S, REST) ==Bool false

  rule hasIntersection(.Strs, NEEDLES:Strs) => false
  rule hasIntersection(SCons(S:String, REST:Strs), NEEDLES:Strs) => true
    requires contains(S, NEEDLES) ==Bool true
  rule hasIntersection(SCons(S:String, REST:Strs), NEEDLES:Strs) =>
       hasIntersection(REST, NEEDLES)
    requires contains(S, NEEDLES) ==Bool false

  rule firstIntersection(.Strs, NEEDLES:Strs) => None
  rule firstIntersection(SCons(S:String, REST:Strs), NEEDLES:Strs) => Some(S)
    requires contains(S, NEEDLES) ==Bool true
  rule firstIntersection(SCons(S:String, REST:Strs), NEEDLES:Strs) =>
       firstIntersection(REST, NEEDLES)
    requires contains(S, NEEDLES) ==Bool false

  // Matches the implementation's validation order: duplicates first, then
  // app default fixture directory conflicts, then accept.
  rule validate(FS:Strs, APPDIRS:Strs) => DuplicateError
    requires hasDuplicate(FS) ==Bool true
  rule validate(FS:Strs, APPDIRS:Strs) =>
       validateDefault(FS, firstIntersection(APPDIRS, FS))
    requires hasDuplicate(FS) ==Bool false

  rule validateDefault(FS:Strs, Some(D:String)) => DefaultFixtureDirError(D)
  rule validateDefault(FS:Strs, None) => Ok(FS)

  rule fixtureDirs(ES:Entries, APPDIRS:Strs) => validate(fspaths(ES), APPDIRS)
endmodule
