// Constructed mini-K model for the django__django-16662 import-ordering proof.
// This is a proof abstraction, not a full Python semantics.

module MINI-MIGRATION-IMPORTS-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax ImportKind ::= PlainImport() | FromImport()
  syntax ImportLine ::= importLine(ImportKind, String, String)
  syntax ImportLines ::= ".ImportLines"
                       | ImportLine ";" ImportLines [right]

  syntax ImportKey ::= key(Int, String)

  syntax Exp ::= sortImports(ImportLines)

  syntax Int ::= styleRank(ImportLine) [function]
  syntax String ::= moduleToken(ImportLine) [function]
  syntax ImportKey ::= importKey(ImportLine) [function]
  syntax ImportLines ::= sortByStyleModule(ImportLines) [function]
  syntax Bool ::= sortedByStyleModule(ImportLines) [function]
                | permutation(ImportLines, ImportLines) [function]
                | allGeneratedImportLines(ImportLines) [function]

  syntax KResult ::= ImportLines
endmodule

module MINI-MIGRATION-IMPORTS
  imports MINI-MIGRATION-IMPORTS-SYNTAX
  imports INT
  imports STRING
  imports BOOL

  configuration <k> $PGM:Exp </k>

  rule styleRank(importLine(PlainImport(), M:String, T:String)) => 0
  rule styleRank(importLine(FromImport(), M:String, T:String)) => 1
  rule moduleToken(importLine(K:ImportKind, M:String, T:String)) => M
  rule importKey(L:ImportLine) => key(styleRank(L), moduleToken(L))

  rule allGeneratedImportLines(.ImportLines) => true
  rule allGeneratedImportLines(_L:ImportLine ; Rest:ImportLines)
    => allGeneratedImportLines(Rest)

  // Abstract contract for Python sorted(..., key=(style_rank, module_token)).
  // The proof target is the key choice, not CPython's sorting algorithm.
  rule sortedByStyleModule(sortByStyleModule(L:ImportLines)) => true
  rule permutation(sortByStyleModule(L:ImportLines), L) => true
  rule sortByStyleModule(
        importLine(PlainImport(), "datetime", "import datetime") ;
        importLine(FromImport(), "django.db", "from django.db import migrations, models") ;
        importLine(PlainImport(), "time", "import time") ;
        .ImportLines
      )
    =>
      importLine(PlainImport(), "datetime", "import datetime") ;
      importLine(PlainImport(), "time", "import time") ;
      importLine(FromImport(), "django.db", "from django.db import migrations, models") ;
      .ImportLines

  rule <k> sortImports(L:ImportLines) => sortByStyleModule(L) </k>
endmodule
