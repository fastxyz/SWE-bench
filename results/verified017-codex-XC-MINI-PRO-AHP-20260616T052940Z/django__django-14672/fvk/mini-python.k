// Constructed, not machine-checked.
// Minimal K-style model for the Python fragment relevant to this audit:
// relation identity tuple construction plus make_hashable-style normalization.

requires "domains.md"

module MINI-M2M-REL-SYNTAX
  imports BOOL
  imports STRING
  imports LIST

  syntax Value ::= none
                 | str(String)
                 | atom(String)
                 | bool(Bool)
                 | list(List)
                 | tuple(List)

  syntax Value ::= makeHashable(Value) [function]
  syntax List  ::= makeHashableList(List) [function]
  syntax Bool  ::= hashable(Value) [function]
  syntax Bool  ::= hashableList(List) [function]

  syntax Value ::= baseIdentity(
      Value, Value, Value, Value, Value, Value, Value, Value, Value
  ) [function]
  syntax Value ::= manyToManyIdentity(
      Value, Value, Value, Value, Value, Value, Value, Value, Value,
      Value, Value, Value
  ) [function]
endmodule

module MINI-M2M-REL
  imports MINI-M2M-REL-SYNTAX

  configuration <k> $PGM:K </k>

  rule makeHashable(none) => none
  rule makeHashable(str(S)) => str(S)
  rule makeHashable(atom(A)) => atom(A)
  rule makeHashable(bool(B)) => bool(B)
  rule makeHashable(tuple(L)) => tuple(makeHashableList(L))
  rule makeHashable(list(L)) => tuple(makeHashableList(L))

  rule makeHashableList(.List) => .List
  rule makeHashableList(ListItem(V) REST) => ListItem(makeHashable(V)) makeHashableList(REST)

  rule hashable(none) => true
  rule hashable(str(_)) => true
  rule hashable(atom(_)) => true
  rule hashable(bool(_)) => true
  rule hashable(list(_)) => false
  rule hashable(tuple(L)) => hashableList(L)

  rule hashableList(.List) => true
  rule hashableList(ListItem(V) REST) => hashable(V) andBool hashableList(REST)

  rule baseIdentity(FIELD, MODEL, RELATED_NAME, RELATED_QUERY_NAME, LIMIT_CHOICES_TO,
                    PARENT_LINK, ON_DELETE, SYMMETRICAL, MULTIPLE)
    => tuple(
         ListItem(FIELD)
         ListItem(MODEL)
         ListItem(RELATED_NAME)
         ListItem(RELATED_QUERY_NAME)
         ListItem(makeHashable(LIMIT_CHOICES_TO))
         ListItem(PARENT_LINK)
         ListItem(ON_DELETE)
         ListItem(SYMMETRICAL)
         ListItem(MULTIPLE)
       )

  rule manyToManyIdentity(FIELD, MODEL, RELATED_NAME, RELATED_QUERY_NAME, LIMIT_CHOICES_TO,
                          PARENT_LINK, ON_DELETE, SYMMETRICAL, MULTIPLE,
                          THROUGH, THROUGH_FIELDS, DB_CONSTRAINT)
    => tuple(
         ListItem(FIELD)
         ListItem(MODEL)
         ListItem(RELATED_NAME)
         ListItem(RELATED_QUERY_NAME)
         ListItem(makeHashable(LIMIT_CHOICES_TO))
         ListItem(PARENT_LINK)
         ListItem(ON_DELETE)
         ListItem(SYMMETRICAL)
         ListItem(MULTIPLE)
         ListItem(THROUGH)
         ListItem(makeHashable(THROUGH_FIELDS))
         ListItem(DB_CONSTRAINT)
       )
endmodule
