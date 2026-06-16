module MINI-AUTODOC-SYNTAX
  imports DOMAINS-SYNTAX

  syntax ClassId ::= r"[A-Za-z_][A-Za-z0-9_.]*" [token]
  syntax AttrId ::= r"[A-Za-z_][A-Za-z0-9_]*" [token]
  syntax Bool ::= "true" | "false"
  syntax MaybeClass ::= ".NoClass" | "class" "(" ClassId ")"
  syntax MaybeDoc ::= ".NoDoc" | "doc" "(" String ")"
  syntax AttrValue ::= "runtime" | "instance"
  syntax Member ::= "member" "(" AttrId "," MaybeClass "," AttrValue "," MaybeDoc ")"
  syntax Members ::= ".Members" | Member "," Members

  syntax Classes ::= ".Classes" | ClassId "," Classes
  syntax AttrDocs ::= ".AttrDocs" | "attrdoc" "(" ClassId "," AttrId "," String ")" "," AttrDocs
  syntax Owners ::= ".Owners" | "owner" "(" AttrId "," MaybeClass ")" "," Owners
endmodule

module MINI-AUTODOC
  imports MINI-AUTODOC-SYNTAX

  // Abstract predicates/functions used by the spec. This fragment models the
  // observable contract rather than the full Python runtime.
  syntax MaybeClass ::= "firstOwner" "(" Classes "," AttrId ")"
  syntax MaybeDoc ::= "firstDoc" "(" Classes "," AttrId "," Owners "," AttrDocs ")"
  syntax MaybeDoc ::= "docForOwner" "(" MaybeClass "," AttrId "," AttrDocs ")"
  syntax Members ::= "collectMembers" "(" ClassId "," Classes "," Owners "," AttrDocs ")"
  syntax Bool ::= "hasMemberDoc" "(" Members "," AttrId ")"
  syntax Bool ::= "selectedAsAttribute" "(" Members "," AttrId ")"
  syntax MaybeDoc ::= "attributeContent" "(" ClassId "," AttrId "," AttrDocs "," Owners ")"

  // Intended equations are supplied in autodoc-inherited-attrs-spec.k as claims.
endmodule

