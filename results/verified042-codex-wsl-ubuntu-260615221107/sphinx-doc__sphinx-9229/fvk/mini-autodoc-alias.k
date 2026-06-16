// Constructed, not machine-checked.
// Minimal K-style semantics for the autodoc alias-content decision audited here.
// It abstracts Python object import and parsing into a public-input flag:
// HasDocComment is true exactly when ModuleAnalyzer.attr_docs contains the
// source-level docstring-comment for the alias being documented.

module MINI-AUTODOC-ALIAS-SYNTAX
  imports BOOL-SYNTAX

  syntax AliasKind ::= genericAlias | newType | typeVar
  syntax Result ::= result ( Bool , Bool , Bool )
  // result(docShown, aliasFallbackShown, dependencyRecorded)

  syntax Exp ::= renderDataAlias ( AliasKind , Bool )
               | renderAttributeAlias ( AliasKind , Bool )
               | renderClassAlias ( Bool )
endmodule

module MINI-AUTODOC-ALIAS
  imports BOOL
  imports MINI-AUTODOC-ALIAS-SYNTAX

  configuration <k> $PGM:Exp </k>

  rule <k> renderDataAlias(_:AliasKind, true)
        => result(true, false, false) ... </k>
  rule <k> renderDataAlias(_:AliasKind, false)
        => result(false, true, false) ... </k>

  rule <k> renderAttributeAlias(_:AliasKind, true)
        => result(true, false, false) ... </k>
  rule <k> renderAttributeAlias(_:AliasKind, false)
        => result(false, true, false) ... </k>

  rule <k> renderClassAlias(true)
        => result(true, false, true) ... </k>
  rule <k> renderClassAlias(false)
        => result(false, true, false) ... </k>
endmodule
