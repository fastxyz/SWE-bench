// Constructed, not machine-checked.
// Mini semantics for the path-canonicalization fragment used by unique_path().

module MINI-PYTHON-PATH-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax PathType ::= PyPathLocal | PathlibPath
  syntax PathObj ::= path(PathType, String)
  syntax KItem ::= uniquePath(PathObj)
  syntax KResult ::= PathObj | PathType | String | Bool
endmodule

module MINI-PYTHON-PATH
  imports MINI-PYTHON-PATH-SYNTAX
  imports MAP
  imports BOOL

  configuration
    <k> $PGM:KItem </k>
    <fs> .Map </fs>

  syntax PathType ::= pathType(PathObj) [function]
  syntax String ::= pathText(PathObj) [function]
  syntax String ::= resolveCanon(String, Map) [function]
  syntax Bool ::= existsPath(String, Map) [function]
  syntax Bool ::= casePreserved(String, Map) [function]
  syntax Bool ::= sameFile(String, String, Map) [function]
  syntax Bool ::= sameCanonical(String, String, Map) [function]

  rule pathType(path(T, _S)) => T
  rule pathText(path(_T, S)) => S

  // Models: return type(path)(str(Path(str(path)).resolve())).
  rule
    <k> uniquePath(P) => path(pathType(P), resolveCanon(pathText(P), FS)) ... </k>
    <fs> FS </fs>
endmodule
