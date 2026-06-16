module MINI-AUTODOC-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX
  imports LIST-SYNTAX

  syntax OptionArg ::= optAbsent | optBare | optTrue | optCsv(List)
  syntax Selector ::= selNone | selAll | selNames(List)
  syntax Members ::= membersAbsent | membersAll | membersList(List)
  syntax Member ::= member(String, Bool, Bool, Bool, Bool, Bool)
  syntax KResult ::= Selector | Members | Bool

  syntax Selector ::= parseMembers(OptionArg) [function]
  syntax Members ::= mergeMembers(Members, Selector) [function]
  syntax List ::= appendMissing(List, List) [function]
  syntax Bool ::= contains(List, String) [function]
                | selected(Selector, String) [function]
                | keepPrivate(Bool, Selector, Member) [function]
endmodule

module MINI-AUTODOC
  imports MINI-AUTODOC-SYNTAX
  imports BOOL
  imports STRING
  imports LIST

  configuration <k> $PGM:K </k>

  // Option conversion mirrors members_option(): a bare option or True means ALL,
  // and a comma-split argument is represented here as an already-trimmed list.
  rule parseMembers(optAbsent) => selNone
  rule parseMembers(optBare) => selAll
  rule parseMembers(optTrue) => selAll
  rule parseMembers(optCsv(NS:List)) => selNames(NS)

  rule contains(.List, N:String) => false
  rule contains(ListItem(N:String) REST:List, N:String) => true
  rule contains(ListItem(M:String) REST:List, N:String) => contains(REST, N)
    requires M =/=String N

  rule appendMissing(MS:List, .List) => MS
  rule appendMissing(MS:List, ListItem(N:String) REST:List) => appendMissing(MS, REST)
    requires contains(MS, N) ==Bool true
  rule appendMissing(MS:List, ListItem(N:String) REST:List) => appendMissing(MS ListItem(N), REST)
    requires contains(MS, N) ==Bool false

  // Explicit selector lists are merged into members; selAll remains a modifier.
  rule mergeMembers(MS:Members, selNone) => MS
  rule mergeMembers(membersAll, selAll) => membersAll
  rule mergeMembers(membersAll, selNames(NS:List)) => membersAll
  rule mergeMembers(membersAbsent, selAll) => membersAbsent
  rule mergeMembers(membersAbsent, selNames(NS:List)) => membersList(NS)
  rule mergeMembers(membersList(MS:List), selAll) => membersList(MS)
  rule mergeMembers(membersList(MS:List), selNames(NS:List)) => membersList(appendMissing(MS, NS))

  rule selected(selNone, N:String) => false
  rule selected(selAll, N:String) => true
  rule selected(selNames(NS:List), N:String) => contains(NS, N)

  // member(Name, IsPrivate, HasDoc, HasAttrDoc, IsExcluded, IsMocked)
  // This abstracts exactly the private-member branches in filter_members().
  rule keepPrivate(WANTALL:Bool, SEL:Selector, member(N:String, true, DOC:Bool, ATTR:Bool, true, MOCK:Bool)) => false
  rule keepPrivate(WANTALL:Bool, SEL:Selector, member(N:String, true, DOC:Bool, ATTR:Bool, EXCL:Bool, true)) => false
  rule keepPrivate(true, SEL:Selector, member(N:String, true, DOC:Bool, true, false, false)) => selected(SEL, N)
  rule keepPrivate(true, SEL:Selector, member(N:String, true, true, false, false, false)) => selected(SEL, N)
  rule keepPrivate(true, SEL:Selector, member(N:String, true, false, false, false, false)) => false
  rule keepPrivate(false, SEL:Selector, member(N:String, true, true, ATTR:Bool, false, false)) => true
  rule keepPrivate(false, SEL:Selector, member(N:String, true, DOC:Bool, true, false, false)) => true
  rule keepPrivate(false, SEL:Selector, member(N:String, true, false, false, false, false)) => false
endmodule
