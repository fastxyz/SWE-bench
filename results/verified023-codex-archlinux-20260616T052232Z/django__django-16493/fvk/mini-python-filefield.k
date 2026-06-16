module MINI-PYTHON-FILEFIELD-SYNTAX
  imports BOOL-SYNTAX

  syntax Storage ::= "defaultStorage"
                   | "otherStorage"

  syntax Callable ::= "getDefaultStorage"
                    | "getOtherStorage"

  syntax StorageArg ::= "noStorageArg"
                      | "direct" "(" Storage ")"
                      | "callable" "(" Callable "," Storage ")"

  syntax MaybeCallable ::= "noCallable"
                         | "someCallable" "(" Callable ")"

  syntax FieldState ::= "field" "(" Storage "," MaybeCallable ")"

  syntax SerializedStorage ::= "serializedStorage" "(" Storage ")"
                             | "serializedCallable" "(" Callable ")"

  syntax DeconstructKwargs ::= "omitStorage"
                             | "includeStorage" "(" SerializedStorage ")"

  syntax Cmd ::= "init" "(" StorageArg ")"
               | "deconstruct" "(" FieldState ")"
               | "initThenDeconstruct" "(" StorageArg ")"

  syntax KResult ::= Storage
                   | Callable
                   | StorageArg
                   | MaybeCallable
                   | FieldState
                   | SerializedStorage
                   | DeconstructKwargs
endmodule

module MINI-PYTHON-FILEFIELD
  imports MINI-PYTHON-FILEFIELD-SYNTAX
  imports BOOL

  configuration <k> $PGM:Cmd </k>

  // FileField.__init__ storage-state abstraction.
  rule <k> init(noStorageArg) => field(defaultStorage, noCallable) </k>
  rule <k> init(direct(defaultStorage)) => field(defaultStorage, noCallable) </k>
  rule <k> init(direct(otherStorage)) => field(otherStorage, noCallable) </k>
  rule <k> init(callable(getDefaultStorage, defaultStorage)) => field(defaultStorage, someCallable(getDefaultStorage)) </k>
  rule <k> init(callable(getOtherStorage, otherStorage)) => field(otherStorage, someCallable(getOtherStorage)) </k>

  // FileField.deconstruct storage-kwarg abstraction for the V1 candidate.
  rule <k> deconstruct(field(defaultStorage, noCallable)) => omitStorage </k>
  rule <k> deconstruct(field(otherStorage, noCallable)) => includeStorage(serializedStorage(otherStorage)) </k>
  rule <k> deconstruct(field(defaultStorage, someCallable(getDefaultStorage))) => includeStorage(serializedCallable(getDefaultStorage)) </k>
  rule <k> deconstruct(field(otherStorage, someCallable(getOtherStorage))) => includeStorage(serializedCallable(getOtherStorage)) </k>

  // End-to-end init followed by deconstruct, specialized to the finite public
  // storage cases needed for this issue.
  rule <k> initThenDeconstruct(noStorageArg) => omitStorage </k>
  rule <k> initThenDeconstruct(direct(defaultStorage)) => omitStorage </k>
  rule <k> initThenDeconstruct(direct(otherStorage)) => includeStorage(serializedStorage(otherStorage)) </k>
  rule <k> initThenDeconstruct(callable(getDefaultStorage, defaultStorage)) => includeStorage(serializedCallable(getDefaultStorage)) </k>
  rule <k> initThenDeconstruct(callable(getOtherStorage, otherStorage)) => includeStorage(serializedCallable(getOtherStorage)) </k>
endmodule
