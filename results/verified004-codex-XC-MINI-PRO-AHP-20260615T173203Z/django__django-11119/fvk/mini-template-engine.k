module MINI-TEMPLATE-ENGINE-SYNTAX
  imports BOOL-SYNTAX

  syntax TemplateName ::= "single" | "many"
  syntax ContextArg ::= "plain" | "existing" "(" Bool ")"
  syntax Result ::= "rendered" "(" Bool ")"
  syntax Exp ::= "renderToString" "(" Bool "," TemplateName "," ContextArg ")"
  syntax KResult ::= Result
endmodule

module MINI-TEMPLATE-ENGINE
  imports MINI-TEMPLATE-ENGINE-SYNTAX
  imports BOOL

  configuration <k> $PGM:Exp </k>

  // Abstracts Engine.render_to_string() after template selection. The Result
  // records the autoescape flag observable by Template.render().
  rule <k> renderToString(EA:Bool, TN:TemplateName, plain) => rendered(EA) </k>
  rule <k> renderToString(EA:Bool, TN:TemplateName, existing(CA:Bool)) => rendered(CA) </k>
endmodule
