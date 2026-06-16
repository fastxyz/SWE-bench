// Abstract mini semantics for the Sphinx autodoc __all__ member-selection
// fragment. Constructed for FVK audit; not machine-checked in this session.

module MINI-PYTHON-AUTODOC-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Name ::= String
  syntax Names ::= ".Names"
                 | Name ";" Names [klabel(names)]

  syntax AllState ::= "noAll"
                    | "exports" "(" Names ")"

  syntax Member ::= "member" "(" Name "," Bool ")"
  syntax Members ::= ".Members"
                   | Member ";" Members [klabel(members)]

  syntax Result ::= "result" "(" Bool "," Members ")"

  syntax Cmd ::= "getObjectMembers" "(" Bool "," AllState "," Members "," Members ")"
               | "filterMembers" "(" Members ")"

  syntax KResult ::= Result | Members | Bool
endmodule

module MINI-PYTHON-AUTODOC
  imports MINI-PYTHON-AUTODOC-SYNTAX
  imports BOOL
  imports STRING

  configuration <k> $PGM:Cmd </k>

  syntax Bool ::= "in" "(" Name "," Names ")" [function]
  rule in(N, .Names) => false
  rule in(N, N ; NS) => true
  rule in(N, M ; NS) => in(N, NS)
    requires N =/=String M

  syntax Members ::= "markSkipped" "(" Names "," Members ")" [function]
  rule markSkipped(NS, .Members) => .Members
  rule markSkipped(NS, member(N, SKIP) ; MS) => member(N, true) ; markSkipped(NS, MS)
    requires notBool in(N, NS)
  rule markSkipped(NS, member(N, SKIP) ; MS) => member(N, SKIP) ; markSkipped(NS, MS)
    requires in(N, NS)

  syntax Members ::= "keepUnskipped" "(" Members ")" [function]
  rule keepUnskipped(.Members) => .Members
  rule keepUnskipped(member(N, true) ; MS) => keepUnskipped(MS)
  rule keepUnskipped(member(N, false) ; MS) => member(N, false) ; keepUnskipped(MS)

  // V1 source equivalent:
  // if want_all and self.__all__ is None: return True, members
  rule <k> getObjectMembers(true, noAll, MS, SELECTED) => result(true, MS) </k>

  // else, for any explicit valid __all__ sequence, mark non-exported members.
  rule <k> getObjectMembers(true, exports(NS), MS, SELECTED)
        => result(false, markSkipped(NS, MS)) </k>

  // Non-want-all branch is unchanged by the fix.
  rule <k> getObjectMembers(false, AS, MS, SELECTED)
        => result(false, SELECTED) </k>

  // Default filtering rule for the forced-skip property under audit.
  rule <k> filterMembers(MS) => keepUnskipped(MS) </k>
endmodule
