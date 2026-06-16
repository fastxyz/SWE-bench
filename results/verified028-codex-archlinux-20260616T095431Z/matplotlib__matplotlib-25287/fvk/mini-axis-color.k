module MINI-AXIS-COLOR-SYNTAX
  imports STRING
  imports MAP

  syntax TickName ::= "xtick" | "ytick"
  syntax KItem ::= resolveColor(TickName)
                 | initOffset(TickName)
                 | initDefaultTickLabels(TickName)
endmodule

module MINI-AXIS-COLOR
  imports MINI-AXIS-COLOR-SYNTAX
  imports BOOL
  imports STRING
  imports MAP

  configuration
    <k> $PGM:K </k>
    <rc> .Map </rc>
    <offsetColor> .Map </offsetColor>
    <tickLabelColor> .Map </tickLabelColor>

  syntax String ::= labelColorKey(TickName) [function]
  rule labelColorKey("xtick") => "xtick.labelcolor"
  rule labelColorKey("ytick") => "ytick.labelcolor"

  syntax String ::= tickColorKey(TickName) [function]
  rule tickColorKey("xtick") => "xtick.color"
  rule tickColorKey("ytick") => "ytick.color"

  syntax String ::= resolveColorFromRc(Map, TickName) [function]
  rule resolveColorFromRc(RC, T) => {RC [tickColorKey(T)]}
    requires {RC [labelColorKey(T)]} ==K "inherit"
  rule resolveColorFromRc(RC, T) => {RC [labelColorKey(T)]}
    requires notBool ({RC [labelColorKey(T)]} ==K "inherit")

  rule <k> resolveColor(T) => resolveColorFromRc(RC, T) ...</k>
       <rc> RC </rc>

  rule <k> initOffset(T) => . ...</k>
       <rc> RC </rc>
       <offsetColor> O => O [T <- resolveColorFromRc(RC, T)] </offsetColor>

  rule <k> initDefaultTickLabels(T) => . ...</k>
       <rc> RC </rc>
       <tickLabelColor> L => L [T <- resolveColorFromRc(RC, T)] </tickLabelColor>
endmodule
