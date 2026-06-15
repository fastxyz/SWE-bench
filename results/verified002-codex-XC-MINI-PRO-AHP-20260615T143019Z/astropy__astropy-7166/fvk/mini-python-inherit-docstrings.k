// Constructed, not machine-checked.
// Mini semantics fragment for the InheritDocstrings audit.
// This abstracts Python class creation to the observable behavior under review:
// member eligibility, MRO lookup, descriptor lookup mode, doc assignment, and
// assignment failure handling.

module MINI-PYTHON-INHERIT-DOCSTRINGS
  imports BOOL
  imports STRING
  imports MAP
  imports LIST

  syntax MaybeDoc ::= "noneDoc" | doc(String)
  syntax Kind ::= "function" | "dataDescriptor" | "other"
  syntax Member ::= member(Kind, Bool, MaybeDoc, Bool)
  // member(kind, isPublic, doc, docWritable)

  syntax MaybeMember ::= "noMember" | found(Member)
  syntax LookupMode ::= "dynamicLookup" | "staticLookup"

  syntax Bool ::= eligible(Member) [function]
  rule eligible(member(function, _, _, _)) => true
  rule eligible(member(dataDescriptor, _, _, _)) => true
  rule eligible(member(other, _, _, _)) => false

  syntax Bool ::= needsDoc(Member) [function]
  rule needsDoc(member(_, _, noneDoc, _)) => true
  rule needsDoc(member(_, _, doc(_), _)) => false

  syntax Bool ::= publicMember(Member) [function]
  rule publicMember(member(_, P, _, _)) => P

  syntax LookupMode ::= lookupMode(Member) [function]
  rule lookupMode(member(dataDescriptor, _, _, _)) => staticLookup
  rule lookupMode(member(function, _, _, _)) => dynamicLookup
  rule lookupMode(member(other, _, _, _)) => dynamicLookup

  syntax Member ::= setDoc(Member, MaybeDoc) [function]
  rule setDoc(member(K, P, _, true), D) => member(K, P, D, true)
  rule setDoc(member(K, P, Old, false), _) => member(K, P, Old, false)

  syntax Member ::= inheritOne(Member, MaybeMember) [function]
  rule inheritOne(M, noMember) => M
  rule inheritOne(M, found(member(_, _, D, _))) => setDoc(M, D)

  syntax Member ::= inheritIfNeeded(Member, MaybeMember) [function]
  rule inheritIfNeeded(M, S) => inheritOne(M, S)
    requires publicMember(M) andBool eligible(M) andBool needsDoc(M)
  rule inheritIfNeeded(M, _) => M
    requires notBool (publicMember(M) andBool eligible(M) andBool needsDoc(M))
endmodule
