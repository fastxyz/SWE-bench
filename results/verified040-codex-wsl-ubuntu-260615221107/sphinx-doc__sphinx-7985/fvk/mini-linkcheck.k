module MINI-LINKCHECK-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax Status ::= "local" | "broken" | "ignored" | "unchecked"
  syntax Result ::= "(" Status "," String ")"
  syntax Cmd ::= check(String, String)
               | checkLocal(String, String)
               | processResult(Result, String)
endmodule

module MINI-LINKCHECK
  imports MINI-LINKCHECK-SYNTAX
  imports STRING
  imports BOOL
  imports MAP
  imports SET

  configuration
    <k> $PGM:Cmd </k>
    <localLinks> true </localLinks>
    <anchors> true </anchors>
    <docUri> .Map </docUri>
    <docAnchors> .Map </docAnchors>
    <files> .Set </files>
    <hasBroken> false </hasBroken>
    <statuscode> 0 </statuscode>

  // Abstract helper predicates for the Python/library operations used by the
  // production implementation. These are specification vocabulary for the FVK
  // proof sketch; this file was not compiled in this benchmark session.
  syntax Bool ::= isHttp(String) [function]
                | isEmpty(String) [function]
                | isMailOrFtp(String) [function]
                | isAbsoluteOrScheme(String) [function]
                | escapesSource(String) [function]
                | ignored(String) [function]
                | ignoredAnchor(String) [function]
                | hasFragment(String) [function]
                | fragmentExists(String, String, Map) [function]
                | localDocExists(String, Map) [function]
                | localFileExists(String, Set) [function]
  syntax String ::= resolvedTarget(String, String) [function]
                  | fragment(String) [function]
                  | docFor(String, String, Map) [function]

  rule <k> check(URI, DOC) => ("unchecked", "") ... </k>
    requires isEmpty(URI) orBool isMailOrFtp(URI)

  rule <k> check(URI, DOC) => ("ignored", "") ... </k>
    requires ignored(URI)

  rule <k> check(URI, DOC) => checkLocal(URI, DOC) ... </k>
    requires notBool isEmpty(URI)
     andBool notBool isMailOrFtp(URI)
     andBool notBool ignored(URI)
     andBool notBool isHttp(URI)

  rule <k> checkLocal(URI, DOC) => ("local", "") ... </k>
       <localLinks> false </localLinks>

  rule <k> checkLocal(URI, DOC) => ("local", "") ... </k>
    requires isAbsoluteOrScheme(URI)

  rule <k> checkLocal(URI, DOC) => ("local", "") ... </k>
       <docUri> DOCURI </docUri>
    requires localDocExists(resolvedTarget(URI, DOC), DOCURI)

  rule <k> checkLocal(URI, DOC) => ("local", "") ... </k>
       <files> FILES </files>
    requires localFileExists(resolvedTarget(URI, DOC), FILES)

  rule <k> checkLocal(URI, DOC) => ("broken", "local file not found") ... </k>
       <docUri> DOCURI </docUri>
       <files> FILES </files>
    requires notBool isAbsoluteOrScheme(URI)
     andBool notBool escapesSource(resolvedTarget(URI, DOC))
     andBool notBool localDocExists(resolvedTarget(URI, DOC), DOCURI)
     andBool notBool localFileExists(resolvedTarget(URI, DOC), FILES)

  rule <k> processResult(("broken", INFO), DOC) => .K ... </k>
       <hasBroken> false => true </hasBroken>
       <statuscode> 0 => 1 </statuscode>
endmodule
