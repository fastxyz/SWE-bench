module MINI-DJANGO-ORDERING-SYNTAX
  imports STRING
  imports LIST
  imports MAP
  imports SET

  syntax Field ::= none | scalar(Set) | relation(String, Set)
  syntax Result ::= ok | e015(String)
  syntax KItem ::= checkPath(String, List, String, Field, Map)
                 | resolvePath(String, List, String, Field, Map)
endmodule

module MINI-DJANGO-ORDERING
  imports MINI-DJANGO-ORDERING-SYNTAX

  configuration <k> $PGM:K </k>

  // Model map shape used by the spec:
  // MODELS[MODEL +String ".pk"] = primary key field name.
  // MODELS[MODEL +String "." +String FIELD] = scalar(TRANSFORMS) or relation(TARGET, TRANSFORMS).

  syntax String ::= pkName(Map, String) [function]
  rule pkName(MODELS, MODEL) => {MODELS[MODEL +String ".pk"]}:>String

  syntax Field ::= modelField(Map, String, String) [function]
  rule modelField(MODELS, MODEL, NAME) => {MODELS[MODEL +String "." +String NAME]}:>Field

  syntax Bool ::= hasTransform(Field, String) [function]
  rule hasTransform(scalar(TS), NAME) => NAME in TS
  rule hasTransform(relation(_, TS), NAME) => NAME in TS

  rule <k> checkPath(ORIGINAL, PARTS, MODEL, PREV, MODELS)
        => resolvePath(ORIGINAL, PARTS, MODEL, PREV, MODELS) ... </k>

  rule <k> resolvePath(_, .List, _, _, _) => ok ... </k>

  // Once a scalar field is reached, remaining pieces are transforms only.
  rule <k> resolvePath(ORIGINAL, ListItem(PART) REST, MODEL, scalar(TS), MODELS)
        => resolvePath(ORIGINAL, REST, MODEL, scalar(TS), MODELS) ... </k>
    requires PART in TS

  rule <k> resolvePath(ORIGINAL, ListItem(PART) REST, _, scalar(TS), _)
        => e015(ORIGINAL) ... </k>
    requires notBool (PART in TS)

  // In model context, pk aliases the current model's concrete primary key.
  rule <k> resolvePath(ORIGINAL, ListItem("pk") REST, MODEL, PREV, MODELS)
        => resolvePath(ORIGINAL, ListItem(pkName(MODELS, MODEL)) REST, MODEL, PREV, MODELS) ... </k>
    requires PREV ==K none orBool isRelation(PREV)

  // Successful relation traversal updates the current model.
  rule <k> resolvePath(ORIGINAL, ListItem(PART) REST, MODEL, PREV, MODELS)
        => resolvePath(ORIGINAL, REST, TARGET, relation(TARGET, TS), MODELS) ... </k>
    requires PREV ==K none orBool isRelation(PREV)
     andBool modelField(MODELS, MODEL, PART) ==K relation(TARGET, TS)

  // Successful scalar field traversal records the scalar; later parts use transform rules.
  rule <k> resolvePath(ORIGINAL, ListItem(PART) REST, MODEL, PREV, MODELS)
        => resolvePath(ORIGINAL, REST, MODEL, scalar(TS), MODELS) ... </k>
    requires PREV ==K none orBool isRelation(PREV)
     andBool modelField(MODELS, MODEL, PART) ==K scalar(TS)

  // If model lookup fails in relation context, a transform on the previous relation may still be valid.
  rule <k> resolvePath(ORIGINAL, ListItem(PART) REST, MODEL, relation(TARGET, TS), MODELS)
        => resolvePath(ORIGINAL, REST, MODEL, relation(TARGET, TS), MODELS) ... </k>
    requires PART in TS

  rule <k> resolvePath(ORIGINAL, ListItem(PART) REST, MODEL, relation(_, TS), MODELS)
        => e015(ORIGINAL) ... </k>
    requires notBool (PART in TS)

  syntax Bool ::= isRelation(Field) [function]
  rule isRelation(relation(_, _)) => true
  rule isRelation(scalar(_)) => false
  rule isRelation(none) => false
endmodule
