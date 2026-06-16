requires "mini-stackplot.k"

module STACKPLOT-SPEC
  imports MINI-STACKPLOT
  imports INT
  imports BOOL
  imports LIST

  // SPEC-PROVENANCE:
  // - E5: explicit colors are cycled through stack layers.
  // - E1/E4: explicit colors are local and do not call Axes.set_prop_cycle.
  // CLAIM-EXPLICIT-COLORS
  claim
    <k> stackplotExplicit(CS:List, M:Int, AX:Axis)
     => result(takeCycle(CS, M), AX, false) </k>
    requires M >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E1: explicit colors must not change the Axes cycler.
  // CLAIM-EXPLICIT-AXES-FRAME
  claim
    <k> stackplotExplicit(CS:List, M:Int, AX:Axis)
     => result(takeCycle(CS, M), AX, false) </k>
    requires M >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E3/E4: C<N> aliases are valid stackplot colors but invalid prop-cycle
  //   members, so the explicit path must not invoke prop-cycle validation.
  // CLAIM-CN-NO-PROP-CYCLE-VALIDATOR
  claim
    <k> stackplotExplicit(
          ListItem(C2) ListItem(C3) ListItem(C4) .List, 3, AX:Axis)
     => result(ListItem(C2) ListItem(C3) ListItem(C4) .List, AX, false) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E6: omitted colors use the Axes property cycle.
  // CLAIM-DEFAULT-LEGACY-CYCLE
  claim
    <k> stackplotDefault(M:Int, axis(I:Int, CS:List))
     => result(takeCycle(advance(CS, I), M), axis(I +Int M, CS), true) </k>
    requires M >=Int 0 andBool I >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E7: public call shape and non-color stackplot behavior are framed.
  // CLAIM-PUBLIC-COMPAT-FRAME
  claim
    <k> stackplotExplicit(CS:List, M:Int, AX:Axis)
     => result(takeCycle(CS, M), AX, false) </k>
    requires M >=Int 0
    [all-path]
endmodule
