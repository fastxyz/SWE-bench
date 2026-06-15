requires "domains.md"

module MINI-PYTHON-FILEFIELD-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports MAP-SYNTAX

  syntax Id ::= String

  syntax StorageResult ::= defaultStorage
                         | storage(Id)
                         | invalid

  syntax StorageArg ::= none
                      | defaultStorageArg
                      | storageArg(Id)
                      | callable(Id, StorageResult)

  syntax MaybeCallable ::= noCallable
                         | someCallable(StorageArg)

  syntax Field ::= field(StorageResult, MaybeCallable, Id)
  syntax Result ::= kwargs(Map)
                  | typeError

  syntax KItem ::= init(StorageArg, Id)
                 | deconstruct(Field, Map)
                 | result(Result)

  syntax Bool ::= isValidStorage(StorageResult) [function]
  syntax StorageResult ::= runtimeStorage(StorageArg) [function]
endmodule

module MINI-PYTHON-FILEFIELD
  imports MINI-PYTHON-FILEFIELD-SYNTAX
  imports INT
  imports BOOL
  imports MAP

  configuration <k> $PGM:K </k>
                <calls> 0 </calls>

  rule isValidStorage(defaultStorage) => true
  rule isValidStorage(storage(_)) => true
  rule isValidStorage(invalid) => false

  rule runtimeStorage(defaultStorageArg) => defaultStorage
  rule runtimeStorage(storageArg(S)) => storage(S)

  rule <k> init(none, U) => result(kwargs(("upload_to" |-> U))) ... </k>

  rule <k> init(defaultStorageArg, U)
        => result(kwargs(("upload_to" |-> U))) ... </k>

  rule <k> init(storageArg(S), U)
        => deconstruct(field(storage(S), noCallable, U), .Map) ... </k>

  rule <k> init(callable(C, S), U)
        => deconstruct(field(S, someCallable(callable(C, S)), U), .Map) ... </k>
       <calls> N => N +Int 1 </calls>
    requires isValidStorage(S)

  rule <k> init(callable(C, invalid), _U) => result(typeError) ... </k>
       <calls> N => N +Int 1 </calls>

  rule <k> deconstruct(field(S, someCallable(C), U), KW)
        => result(kwargs(KW ["upload_to" <- U] ["storage" <- C])) ... </k>

  rule <k> deconstruct(field(defaultStorage, noCallable, U), KW)
        => result(kwargs(KW ["upload_to" <- U])) ... </k>

  rule <k> deconstruct(field(storage(S), noCallable, U), KW)
        => result(kwargs(KW ["upload_to" <- U] ["storage" <- storageArg(S)])) ... </k>
endmodule
