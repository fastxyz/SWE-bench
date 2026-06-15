module MINI-LOADER-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX
  imports LIST-SYNTAX
  imports SET-SYNTAX

  syntax PathEntry ::= "pathEntry" "(" String "," Bool "," Bool ")"
  syntax Outcome ::= "disabled"
                   | "missingOk"
                   | "importError"
                   | "loaded" "(" Bool "," Bool "," List ")"
  // loaded(HAS_PATH, HAS_FILE, PATH_ENTRIES)
  // HAS_FILE is intentionally not used by the migrated/unmigrated classifier.

  syntax Decision ::= "unmigrated"
                    | "migrated" "(" Set ")"
                    | "raisedImportError"
                    | "badMigration" "(" String ")"
  syntax KResult ::= Decision

  syntax Exp ::= "classify" "(" Outcome ")"
endmodule

module MINI-LOADER
  imports MINI-LOADER-SYNTAX
  imports BOOL
  imports STRING
  imports SET
  imports LIST

  configuration <k> $PGM:Exp </k>

  rule <k> classify(disabled) => unmigrated </k>
  rule <k> classify(missingOk) => unmigrated </k>
  rule <k> classify(importError) => raisedImportError </k>
  rule <k> classify(loaded(false, _HAS_FILE:Bool, _ENTRIES:List)) => unmigrated </k>
  rule <k> classify(loaded(true, _HAS_FILE:Bool, ENTRIES:List)) => migrated(filterNames(ENTRIES)) </k>

  // Abstract specification of the existing pkgutil.iter_modules filter:
  // keep non-package names whose first character is neither "_" nor "~".
  syntax Bool ::= keep(PathEntry) [function]
  rule keep(pathEntry(_N:String, true, _IGN:Bool)) => false
  rule keep(pathEntry(_N:String, false, true)) => false
  rule keep(pathEntry(_N:String, false, false)) => true

  syntax String ::= entryName(PathEntry) [function]
  rule entryName(pathEntry(N:String, _IS_PKG:Bool, _IGNORED:Bool)) => N

  syntax Set ::= filterNames(List) [function]
  rule filterNames(.List) => .Set
  rule filterNames(ListItem(E:PathEntry) REST:List) => SetItem(entryName(E)) filterNames(REST)
    requires keep(E)
  rule filterNames(ListItem(E:PathEntry) REST:List) => filterNames(REST)
    requires notBool keep(E)
endmodule
