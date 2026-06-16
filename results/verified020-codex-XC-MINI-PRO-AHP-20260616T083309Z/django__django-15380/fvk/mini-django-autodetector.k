module MINI-DJANGO-AUTODETECTOR-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax Key ::= key(String, String)
  syntax FieldKey ::= fieldKey(String, String, String)

  syntax Cmd ::= modelRename(String, String, String)
               | prepareFieldLists(String, String, String, String)
               | v0Lookup(FieldKey)
               | v1Lookup(FieldKey)
               | noRenameLookup(String, String, String)
               | done
endmodule

module MINI-DJANGO-AUTODETECTOR
  imports MINI-DJANGO-AUTODETECTOR-SYNTAX
  imports MAP
  imports SET
  imports BOOL
  imports STRING

  configuration
    <k> $PGM:Cmd </k>
    <fromModels> .Set </fromModels>
    <toModels> .Set </toModels>
    <oldModelKeys> .Set </oldModelKeys>
    <newModelKeys> .Set </newModelKeys>
    <renamedModels> .Map </renamedModels>
    <oldFieldKeys> .Set </oldFieldKeys>
    <newFieldKeys> .Set </newFieldKeys>
    <lookupDefined> false </lookupDefined>

  rule
    <k> modelRename(A, O, N) => done </k>
    <oldModelKeys> OMS => (OMS -Set SetItem(key(A, O))) |Set SetItem(key(A, N)) </oldModelKeys>
    <renamedModels> RMS => RMS [ key(A, N) <- O ] </renamedModels>
    requires key(A, O) in OMS
     andBool key(A, N) =/=K key(A, O)

  rule
    <k> prepareFieldLists(A, O, N, F) => done </k>
    <renamedModels> ... key(A, N) |-> O ... </renamedModels>
    <fromModels> FROM </fromModels>
    <toModels> TO </toModels>
    <oldFieldKeys> OFS => OFS |Set SetItem(fieldKey(A, N, F)) </oldFieldKeys>
    <newFieldKeys> NFS => NFS |Set SetItem(fieldKey(A, N, F)) </newFieldKeys>
    requires key(A, O) in FROM
     andBool key(A, N) in TO

  rule
    <k> v0Lookup(fieldKey(A, N, F)) => done </k>
    <renamedModels> ... key(A, N) |-> O ... </renamedModels>
    <toModels> TO </toModels>
    <lookupDefined> _ => key(A, O) in TO </lookupDefined>

  rule
    <k> v1Lookup(fieldKey(A, N, F)) => done </k>
    <toModels> TO </toModels>
    <lookupDefined> _ => key(A, N) in TO </lookupDefined>

  rule
    <k> noRenameLookup(A, M, F) => done </k>
    <renamedModels> RMS </renamedModels>
    <toModels> TO </toModels>
    <lookupDefined> _ => key(A, M) in TO </lookupDefined>
    requires notBool (key(A, M) in_keys RMS)

  syntax Bool ::= Key "in_keys" Map [function]
  rule K in_keys(.Map) => false
  rule K in_keys((K |-> _) M:Map) => true
  rule K in_keys((K2 |-> _) M:Map) => K in_keys M requires K =/=K K2
endmodule
