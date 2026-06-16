module MINI-PYTHON-ATTRS-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports MAP-SYNTAX

  syntax Mode ::= override | drop | noConflicts | identical | badMode
  syntax AttrObj ::= attr(Int, Map)
  syntax AttrList ::= emptyAttrs | consAttr(AttrObj, AttrList)
  syntax Result ::= AttrObj | none | mergeError | valueError
  syntax Pgm ::= mergeAttrs(AttrList, Mode)

  syntax Map ::= unionNoConflicts(AttrList) [function]
  syntax Bool ::= compatibleNoConflicts(AttrList) [function]
  syntax Bool ::= allIdentical(AttrList) [function]
  syntax Map ::= firstContents(AttrList) [function]

  syntax KResult ::= Result
endmodule

module MINI-PYTHON-ATTRS
  imports MINI-PYTHON-ATTRS-SYNTAX
  imports INT
  imports BOOL
  imports MAP

  configuration
    <k> $PGM:Pgm </k>
    <nextId> 1 </nextId>

  rule firstContents(consAttr(attr(ID, M), REST)) => M

  rule <k> mergeAttrs(emptyAttrs, MODE) => none ... </k>

  rule <k> mergeAttrs(ATTRS, drop) => attr(N, .Map) ... </k>
       <nextId> N => N +Int 1 </nextId>
    requires ATTRS =/=K emptyAttrs

  rule <k> mergeAttrs(consAttr(attr(ID0, M0), REST), override) => attr(N, M0) ... </k>
       <nextId> N => N +Int 1 </nextId>
    requires N =/=Int ID0

  rule <k> mergeAttrs(ATTRS, noConflicts) => attr(N, unionNoConflicts(ATTRS)) ... </k>
       <nextId> N => N +Int 1 </nextId>
    requires ATTRS =/=K emptyAttrs andBool compatibleNoConflicts(ATTRS)

  rule <k> mergeAttrs(ATTRS, noConflicts) => mergeError ... </k>
    requires ATTRS =/=K emptyAttrs andBool notBool compatibleNoConflicts(ATTRS)

  rule <k> mergeAttrs(ATTRS, identical) => attr(N, firstContents(ATTRS)) ... </k>
       <nextId> N => N +Int 1 </nextId>
    requires ATTRS =/=K emptyAttrs andBool allIdentical(ATTRS)

  rule <k> mergeAttrs(ATTRS, identical) => mergeError ... </k>
    requires ATTRS =/=K emptyAttrs andBool notBool allIdentical(ATTRS)

  rule <k> mergeAttrs(ATTRS, badMode) => valueError ... </k>
    requires ATTRS =/=K emptyAttrs
endmodule
