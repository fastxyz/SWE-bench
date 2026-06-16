module MINI-TOCTREE-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX
  imports MAP-SYNTAX
  imports SET-SYNTAX
  imports LIST-SYNTAX

  syntax Cmd ::= parse(String, String)
               | resolve(String, String)
               | assignSection(String)
               | assignFigure(String)

  syntax Label ::= label(String, String)  // target docname, display title
  syntax Entry ::= entry(String, String)  // explicit title, ref
  syntax Link ::= link(String, String)    // target docname, display title
  syntax Warning ::= warning(String)
  syntax KResult ::= Bool | String
endmodule

module MINI-TOCTREE
  imports MINI-TOCTREE-SYNTAX
  imports BOOL
  imports STRING
  imports MAP
  imports SET
  imports LIST

  configuration
    <k> $PGM:Cmd </k>
    <foundDocs> .Set </foundDocs>
    <labels> .Map </labels>
    <entries> .List </entries>
    <includefiles> .List </includefiles>
    <warnings> .List </warnings>
    <links> .List </links>
    <sectionNumbers> .List </sectionNumbers>
    <figureNumbers> .List </figureNumbers>

  syntax Bool ::= generatedName(String) [function]
  rule generatedName("genindex") => true
  rule generatedName("modindex") => true
  rule generatedName("search") => true
  rule generatedName(REF:String) => false [owise]

  syntax String ::= targetOf(String, Map) [function]
  rule targetOf(REF:String, ... REF |-> label(TARGET:String, _TITLE:String) ...) => TARGET

  syntax String ::= titleOf(String, Map) [function]
  rule titleOf(REF:String, ... REF |-> label(_TARGET:String, TITLE:String) ...) => TITLE

  syntax String ::= displayTitle(String, String) [function]
  rule displayTitle("", DEFAULT:String) => DEFAULT
  rule displayTitle(EXPLICIT:String, _DEFAULT:String) => EXPLICIT requires EXPLICIT =/=String ""

  syntax Bool ::= generatedTarget(String, Map, Set) [function]
  rule generatedTarget(REF:String, LABELS:Map, FOUND:Set)
    => generatedName(REF)
       andBool notBool(targetOf(REF, LABELS) in FOUND)

  rule
    <k> parse(TITLE:String, REF:String) => .K ... </k>
    <foundDocs> FOUND:Set </foundDocs>
    <labels> LABELS:Map </labels>
    <entries> ES:List => ES ListItem(entry(TITLE, REF)) </entries>
    <includefiles> IS:List => IS </includefiles>
    <warnings> WS:List => WS </warnings>
  requires generatedTarget(REF, LABELS, FOUND)

  rule
    <k> parse(TITLE:String, DOC:String) => .K ... </k>
    <foundDocs> FOUND:Set </foundDocs>
    <entries> ES:List => ES ListItem(entry(TITLE, DOC)) </entries>
    <includefiles> IS:List => IS ListItem(DOC) </includefiles>
    <warnings> WS:List => WS </warnings>
  requires DOC in FOUND

  rule
    <k> parse(_TITLE:String, REF:String) => .K ... </k>
    <foundDocs> FOUND:Set </foundDocs>
    <labels> LABELS:Map </labels>
    <entries> ES:List => ES </entries>
    <includefiles> IS:List => IS </includefiles>
    <warnings> WS:List => WS ListItem(warning(REF)) </warnings>
  requires notBool(REF in FOUND)
       andBool notBool(generatedTarget(REF, LABELS, FOUND))

  rule
    <k> resolve(TITLE:String, REF:String) => .K ... </k>
    <foundDocs> FOUND:Set </foundDocs>
    <labels> LABELS:Map </labels>
    <links> LS:List
      => LS ListItem(link(targetOf(REF, LABELS),
                          displayTitle(TITLE, titleOf(REF, LABELS))))
    </links>
    <warnings> WS:List => WS </warnings>
  requires generatedTarget(REF, LABELS, FOUND)

  rule
    <k> assignSection(REF:String) => .K ... </k>
    <foundDocs> FOUND:Set </foundDocs>
    <labels> LABELS:Map </labels>
    <sectionNumbers> SN:List => SN </sectionNumbers>
    <warnings> WS:List => WS </warnings>
  requires generatedTarget(REF, LABELS, FOUND)

  rule
    <k> assignFigure(REF:String) => .K ... </k>
    <foundDocs> FOUND:Set </foundDocs>
    <labels> LABELS:Map </labels>
    <figureNumbers> FN:List => FN </figureNumbers>
    <warnings> WS:List => WS </warnings>
  requires generatedTarget(REF, LABELS, FOUND)
endmodule

