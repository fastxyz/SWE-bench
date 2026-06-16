module MINI-AUTODOC-SYNTAX
  imports BOOL-SYNTAX

  syntax Meta ::= "noneMeta" | "publicMeta" | "privateMeta" | "bothMeta"
  syntax Decision ::= "decision" "(" Bool "," Bool ")"

  // filterMember(NamePrivate, DocMeta, AttrPresent, AttrMeta,
  //              WantAll, PrivateAllowed, Excluded, Special, SpecialAllowed,
  //              HasDoc, UndocMembers, Mocked, Skipped)
  syntax KItem ::= "filterMember" "(" Bool "," Meta "," Bool "," Meta ","
                                      Bool "," Bool "," Bool "," Bool "," Bool ","
                                      Bool "," Bool "," Bool "," Bool ")"
endmodule

module MINI-AUTODOC
  imports MINI-AUTODOC-SYNTAX
  imports BOOL

  configuration <k> $PGM:K </k>

  syntax Bool ::= hasVisibility(Meta) [function]
  rule hasVisibility(noneMeta) => false
  rule hasVisibility(publicMeta) => true
  rule hasVisibility(privateMeta) => true
  rule hasVisibility(bothMeta) => true

  syntax Bool ::= metaPrivate(Meta) [function]
  rule metaPrivate(noneMeta) => false
  rule metaPrivate(publicMeta) => false
  rule metaPrivate(privateMeta) => true
  rule metaPrivate(bothMeta) => true

  // Attribute documentation is the effective documentation source for
  // variables when it carries a visibility marker.  Otherwise, docstring
  // metadata and finally the leading-underscore name rule remain in force.
  syntax Bool ::= choosePrivate(Bool, Meta, Bool, Meta) [function]
  rule choosePrivate(NAMEPRIVATE:Bool, DOCMETA:Meta, true, ATTRMETA:Meta)
    => metaPrivate(ATTRMETA)
    requires hasVisibility(ATTRMETA)
  rule choosePrivate(NAMEPRIVATE:Bool, DOCMETA:Meta, ATTRPRESENT:Bool, ATTRMETA:Meta)
    => metaPrivate(DOCMETA)
    requires notBool (ATTRPRESENT andBool hasVisibility(ATTRMETA))
         andBool hasVisibility(DOCMETA)
  rule choosePrivate(NAMEPRIVATE:Bool, DOCMETA:Meta, ATTRPRESENT:Bool, ATTRMETA:Meta)
    => NAMEPRIVATE
    requires notBool (ATTRPRESENT andBool hasVisibility(ATTRMETA))
         andBool notBool hasVisibility(DOCMETA)

  syntax Bool ::= attrKeep(Bool, Bool, Bool) [function]
  rule attrKeep(ISPRIVATE:Bool, WANTALL:Bool, PRIVATEALLOWED:Bool)
    => (notBool (WANTALL andBool ISPRIVATE)) orBool PRIVATEALLOWED

  syntax Bool ::= nonAttrKeep(Bool, Bool, Bool, Bool, Bool) [function]
  rule nonAttrKeep(true, true, PRIVATEALLOWED:Bool, HASDOC:Bool, UNDOC:Bool)
    => (HASDOC orBool UNDOC) andBool PRIVATEALLOWED
  rule nonAttrKeep(ISPRIVATE:Bool, WANTALL:Bool, PRIVATEALLOWED:Bool, HASDOC:Bool, UNDOC:Bool)
    => HASDOC orBool UNDOC
    requires notBool (WANTALL andBool ISPRIVATE)

  rule <k> filterMember(NAMEPRIVATE:Bool, DOCMETA:Meta, ATTRPRESENT:Bool, ATTRMETA:Meta,
                        WANTALL:Bool, PRIVATEALLOWED:Bool, EXCLUDED:Bool,
                        SPECIAL:Bool, SPECIALALLOWED:Bool, HASDOC:Bool, UNDOC:Bool,
                        MOCKED:Bool, SKIPPED:Bool)
        => decision(false, false) </k>
    requires MOCKED orBool EXCLUDED orBool SKIPPED

  rule <k> filterMember(NAMEPRIVATE:Bool, DOCMETA:Meta, ATTRPRESENT:Bool, ATTRMETA:Meta,
                        true, PRIVATEALLOWED:Bool, false,
                        true, false, HASDOC:Bool, UNDOC:Bool,
                        false, false)
        => decision(false, false) </k>

  rule <k> filterMember(NAMEPRIVATE:Bool, DOCMETA:Meta, ATTRPRESENT:Bool, ATTRMETA:Meta,
                        WANTALL:Bool, PRIVATEALLOWED:Bool, false,
                        true, true, HASDOC:Bool, UNDOC:Bool,
                        false, false)
        => decision(HASDOC orBool UNDOC, false) </k>

  rule <k> filterMember(NAMEPRIVATE:Bool, DOCMETA:Meta, true, ATTRMETA:Meta,
                        WANTALL:Bool, PRIVATEALLOWED:Bool, false,
                        false, SPECIALALLOWED:Bool, HASDOC:Bool, UNDOC:Bool,
                        false, false)
        => decision(attrKeep(choosePrivate(NAMEPRIVATE, DOCMETA, true, ATTRMETA),
                             WANTALL, PRIVATEALLOWED),
                    true) </k>

  rule <k> filterMember(NAMEPRIVATE:Bool, DOCMETA:Meta, false, ATTRMETA:Meta,
                        WANTALL:Bool, PRIVATEALLOWED:Bool, false,
                        false, SPECIALALLOWED:Bool, HASDOC:Bool, UNDOC:Bool,
                        false, false)
        => decision(nonAttrKeep(choosePrivate(NAMEPRIVATE, DOCMETA, false, ATTRMETA),
                                WANTALL, PRIVATEALLOWED, HASDOC, UNDOC),
                    false) </k>
endmodule
