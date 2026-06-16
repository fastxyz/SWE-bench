module MINI-SPHINX-INCLUDE-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX

  syntax Stmt ::= includeRun(Bool, String, String)
                | baseIncludeRead(String)
                | restoreInput(String, String)
                | durationOnSourceRead(Int)

  syntax Source ::= sourceRead(String, String) [function]
  syntax KResult ::= String | Bool | Int | Source
endmodule

module MINI-SPHINX-INCLUDE
  imports MINI-SPHINX-INCLUDE-SYNTAX
  imports BOOL
  imports INT
  imports STRING
  imports MAP
  imports LIST

  configuration
    <k> $PGM:Stmt </k>
    <files> .Map </files>
    <pathdocs> .Map </pathdocs>
    <inserted> .Map </inserted>
    <events> .List </events>
    <fileInput> "orig" </fileInput>
    <directFileInput> "none" </directFileInput>
    <currentDoc> "" </currentDoc>
    <durationStarted> false </durationStarted>
    <startedAt> 0 </startedAt>

  // Standard docutils includes bypass Sphinx wrapping.
  rule <k> includeRun(true, _CUR, FILE) => baseIncludeRead(FILE) ... </k>

  // Managed includes patch the module-level FileInput lookup.
  rule <k> includeRun(false, CUR, FILE) => baseIncludeRead(FILE) ~> restoreInput(OLD, DIRECT) ... </k>
       <fileInput> OLD => "sphinx" </fileInput>
       <directFileInput> DIRECT => "sphinx" </directFileInput>
       <currentDoc> _ => CUR </currentDoc>
    requires DIRECT =/=String "none"

  rule <k> includeRun(false, CUR, FILE) => baseIncludeRead(FILE) ~> restoreInput(OLD, DIRECT) ... </k>
       <fileInput> OLD => "sphinx" </fileInput>
       <directFileInput> DIRECT </directFileInput>
       <currentDoc> _ => CUR </currentDoc>
    requires DIRECT ==String "none"

  // The wrapped read emits source-read and returns the transformed source.
  rule <k> baseIncludeRead(FILE) => .K ... </k>
       <files> ... FILE |-> SRC:String ... </files>
       <pathdocs> ... FILE |-> DOC:String ... </pathdocs>
       <inserted> INS => INS [ FILE <- sourceRead(DOC, SRC) ] </inserted>
       <events> EVS => EVS ListItem(DOC +String ":" +String SRC) </events>
       <fileInput> "sphinx" </fileInput>

  rule <k> baseIncludeRead(FILE) => .K ... </k>
       <files> ... FILE |-> SRC:String ... </files>
       <pathdocs> .Map </pathdocs>
       <inserted> INS => INS [ FILE <- sourceRead(CUR, SRC) ] </inserted>
       <events> EVS => EVS ListItem(CUR +String ":" +String SRC) </events>
       <fileInput> "sphinx" </fileInput>
       <currentDoc> CUR </currentDoc>
       requires CUR =/=String ""

  // Restoration models the finally block.
  rule <k> restoreInput(OLD, DIRECT) => .K ... </k>
       <fileInput> _ => OLD </fileInput>
       <directFileInput> _ => DIRECT </directFileInput>

  // Duration starts once per document read.
  rule <k> durationOnSourceRead(NOW) => .K ... </k>
       <durationStarted> false => true </durationStarted>
       <startedAt> _ => NOW </startedAt>

  rule <k> durationOnSourceRead(_NOW) => .K ... </k>
       <durationStarted> true </durationStarted>
endmodule
