module MINI-ADMIN-WIDGET-SYNTAX
  imports BOOL-SYNTAX

  syntax Widget ::= explicitWidget | autocompleteWidget | rawIdWidget | filteredWidget | defaultWidget
  syntax MaybeWidget ::= noWidget | someWidget(Widget)
  syntax AdminOption ::= noAdminWidget | autocompleteOption | rawIdOption | filteredOption
  syntax QuerysetState ::= noQueryset | explicitQueryset | inferredQueryset
  syntax FormField ::= noFormField | formField(Widget, QuerysetState)
  syntax KItem ::= m2mFormfield(Bool, MaybeWidget, AdminOption, QuerysetState)
                 | finalize(Widget, QuerysetState)
endmodule

module MINI-ADMIN-WIDGET
  imports MINI-ADMIN-WIDGET-SYNTAX

  configuration <k> $PGM:K </k>

  rule <k> m2mFormfield(false, _:MaybeWidget, _:AdminOption, _:QuerysetState) => noFormField ... </k>

  rule <k> m2mFormfield(true, someWidget(W), _:AdminOption, Q) => finalize(W, Q) ... </k>

  rule <k> m2mFormfield(true, noWidget, autocompleteOption, Q) => finalize(autocompleteWidget, Q) ... </k>
  rule <k> m2mFormfield(true, noWidget, rawIdOption, Q) => finalize(rawIdWidget, Q) ... </k>
  rule <k> m2mFormfield(true, noWidget, filteredOption, Q) => finalize(filteredWidget, Q) ... </k>
  rule <k> m2mFormfield(true, noWidget, noAdminWidget, Q) => finalize(defaultWidget, Q) ... </k>

  rule <k> finalize(W, noQueryset) => formField(W, inferredQueryset) ... </k>
  rule <k> finalize(W, explicitQueryset) => formField(W, explicitQueryset) ... </k>
  rule <k> finalize(W, inferredQueryset) => formField(W, inferredQueryset) ... </k>
endmodule
