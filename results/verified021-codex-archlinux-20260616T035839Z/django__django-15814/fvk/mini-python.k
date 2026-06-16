module MINI-PYTHON-SYNTAX
  imports BOOL-SYNTAX

  syntax Model ::= "anotherModel"
                 | "customModel"
                 | "proxyCustomModel"
                 | "trackerUser"
                 | "proxyTrackerUser"

  syntax Field ::= "customFk"
                 | "assigneeFk"
                 | "idField"
                 | "nameField"
                 | "statusField"

  syntax KeyedField ::= "key" "(" Model "," Field ")"
  syntax KeyedFields ::= ".KeyedFields"
                       | KeyedField KeyedFields [right]

  syntax Fields ::= ".Fields"
                  | Field Fields [right]

  syntax Stmt ::= "buildOnlyMask" "(" Model "," Model "," Field "," Field ")"
                | "legacyBuildOnlyMask" "(" Model "," Model "," Field "," Field ")"
                | "defaultColumns" "(" Model ")"

  syntax KResult ::= Model | Field | KeyedFields | Fields
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports BOOL

  configuration
    <k> $PGM:Stmt </k>
    <mustInclude> .KeyedFields </mustInclude>
    <seen> .KeyedFields </seen>
    <loadMask> .KeyedFields </loadMask>
    <selected> .Fields </selected>

  syntax Model ::= concrete(Model) [function]
  rule concrete(proxyCustomModel) => customModel
  rule concrete(proxyTrackerUser) => trackerUser
  rule concrete(M:Model) => M [owise]

  syntax Field ::= pk(Model) [function]
  rule pk(customModel) => idField
  rule pk(trackerUser) => idField
  rule pk(M:Model) => idField [owise]

  syntax Model ::= owner(Field) [function]
  rule owner(customFk) => anotherModel
  rule owner(assigneeFk) => anotherModel
  rule owner(idField) => customModel
  rule owner(nameField) => customModel
  rule owner(statusField) => trackerUser

  syntax Bool ::= hasKeyField(KeyedFields, Model, Field) [function]
  rule hasKeyField(.KeyedFields, M:Model, F:Field) => false
  rule hasKeyField(key(M:Model, F:Field) REST:KeyedFields, M, F) => true
  rule hasKeyField(key(M1:Model, F1:Field) REST:KeyedFields, M2:Model, F2:Field) =>
       hasKeyField(REST, M2, F2)
       [owise]

  syntax Bool ::= hasField(Fields, Field) [function]
  rule hasField(.Fields, F:Field) => false
  rule hasField(F:Field REST:Fields, F) => true
  rule hasField(F1:Field REST:Fields, F2:Field) => hasField(REST, F2) [owise]

  syntax Fields ::= concat(Fields, Fields) [function]
  rule concat(.Fields, FS:Fields) => FS
  rule concat(F:Field FS1:Fields, FS2:Fields) => F concat(FS1, FS2)

  syntax Fields ::= maybeSelect(KeyedFields, Model, Field) [function]
  rule maybeSelect(LM:KeyedFields, M:Model, F:Field) => F .Fields
       requires hasKeyField(LM, M, F)
  rule maybeSelect(LM:KeyedFields, M:Model, F:Field) => .Fields
       requires notBool hasKeyField(LM, M, F)

  syntax Fields ::= selectedFor(Model, KeyedFields) [function]
  rule selectedFor(customModel, LM:KeyedFields) =>
       concat(maybeSelect(LM, customModel, idField),
              maybeSelect(LM, customModel, nameField))
  rule selectedFor(trackerUser, LM:KeyedFields) =>
       concat(maybeSelect(LM, trackerUser, idField),
              maybeSelect(LM, trackerUser, statusField))

  // Fixed behavior: after following a relation, the target traversal model is
  // normalized to its concrete model before the required primary key is stored.
  rule
    <k> buildOnlyMask(ROOT:Model, TARGET:Model, SOURCE:Field, FINAL:Field)
        => .K ... </k>
    <mustInclude> _ => key(ROOT, SOURCE)
                       key(concrete(TARGET), pk(concrete(TARGET)))
                       .KeyedFields </mustInclude>
    <seen> _ => key(owner(FINAL), FINAL) .KeyedFields </seen>
    <loadMask> _ => key(owner(FINAL), FINAL)
                    key(ROOT, SOURCE)
                    key(concrete(TARGET), pk(concrete(TARGET)))
                    .KeyedFields </loadMask>

  // Pre-fix behavior used only for the counterexample: the target primary key
  // is stored under the proxy target key, not the concrete key.
  rule
    <k> legacyBuildOnlyMask(ROOT:Model, TARGET:Model, SOURCE:Field, FINAL:Field)
        => .K ... </k>
    <mustInclude> _ => key(ROOT, SOURCE)
                       key(TARGET, pk(concrete(TARGET)))
                       .KeyedFields </mustInclude>
    <seen> _ => key(owner(FINAL), FINAL) .KeyedFields </seen>
    <loadMask> _ => key(owner(FINAL), FINAL)
                    key(ROOT, SOURCE)
                    key(TARGET, pk(concrete(TARGET)))
                    .KeyedFields </loadMask>

  rule
    <k> defaultColumns(M:Model) => .K ... </k>
    <loadMask> LM:KeyedFields </loadMask>
    <selected> _ => selectedFor(M, LM) </selected>
endmodule
