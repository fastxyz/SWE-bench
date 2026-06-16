// Constructed mini semantics for matplotlib log-limit normalization.
// Not machine-checked in this session.
//
// Modeling note:
// Ordered Int values abstract finite Python numeric axis limits. This
// abstraction preserves the property under verification: positivity and pair
// order. The bug is independent of floating-point arithmetic beyond those
// comparisons.

module MINI-PYTHON-LOG-LIMITS-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Pair ::= pair(Int, Int)

  syntax Pair ::= logNonsingular(Int, Int, Int, Bool, Bool) [function]
                | logNonsingularSorted(Int, Int, Int, Bool) [function]
                | pairOut(Bool, Int, Int) [function]
                | limitRangeForLog(Pair, Int) [function]
                | axisSetLogLimits(Int, Int, Int) [function]

  syntax Int ::= clampPositive(Int, Int) [function]
               | decadeLess(Int) [function]
               | decadeGreater(Int) [function]

  syntax Bool ::= isInverted(Pair) [function]

  syntax KResult ::= Pair | Bool
endmodule

module MINI-PYTHON-LOG-LIMITS
  imports MINI-PYTHON-LOG-LIMITS-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:K </k>

  // Reduced model of:
  //   if not np.isfinite(vmin) or not np.isfinite(vmax): return 1, 10
  rule logNonsingular(VMIN:Int, VMAX:Int, MINPOS:Int, false, FMAX:Bool)
    => pair(1, 10)
  rule logNonsingular(VMIN:Int, VMAX:Int, MINPOS:Int, FMIN:Bool, false)
    => pair(1, 10)

  // Reduced model of the V1 swapped flag and internal sorting.
  rule logNonsingular(VMIN:Int, VMAX:Int, MINPOS:Int, true, true)
    => logNonsingularSorted(VMAX, VMIN, MINPOS, true)
    requires VMIN >Int VMAX
  rule logNonsingular(VMIN:Int, VMAX:Int, MINPOS:Int, true, true)
    => logNonsingularSorted(VMIN, VMAX, MINPOS, false)
    requires VMIN <=Int VMAX

  // Existing all-nonpositive fallback.
  rule logNonsingularSorted(VMIN:Int, VMAX:Int, MINPOS:Int, SWAPPED:Bool)
    => pair(1, 10)
    requires VMAX <=Int 0

  // Existing minpos substitution for a nonpositive lower bound.
  rule logNonsingularSorted(VMIN:Int, VMAX:Int, MINPOS:Int, SWAPPED:Bool)
    => pairOut(SWAPPED, MINPOS, VMAX)
    requires VMIN <=Int 0 andBool VMAX >Int 0
      andBool MINPOS >Int 0 andBool MINPOS =/=Int VMAX

  // Existing singular positive expansion.
  rule logNonsingularSorted(VMIN:Int, VMAX:Int, MINPOS:Int, SWAPPED:Bool)
    => pairOut(SWAPPED, decadeLess(VMIN), decadeGreater(VMAX))
    requires VMIN ==Int VMAX andBool VMIN >Int 0

  // Unequal positive limits are already nonsingular; V1 restores input order.
  rule logNonsingularSorted(VMIN:Int, VMAX:Int, MINPOS:Int, SWAPPED:Bool)
    => pairOut(SWAPPED, VMIN, VMAX)
    requires VMIN >Int 0 andBool VMAX >Int 0 andBool VMIN =/=Int VMAX

  rule pairOut(false, VMIN:Int, VMAX:Int) => pair(VMIN, VMAX)
  rule pairOut(true,  VMIN:Int, VMAX:Int) => pair(VMAX, VMIN)

  // Reduced model of LogScale.limit_range_for_scale.
  rule limitRangeForLog(pair(VMIN:Int, VMAX:Int), MINPOS:Int)
    => pair(clampPositive(VMIN, MINPOS), clampPositive(VMAX, MINPOS))
  rule clampPositive(V:Int, MINPOS:Int) => V requires V >Int 0
  rule clampPositive(V:Int, MINPOS:Int) => MINPOS requires V <=Int 0

  // Reduced in-domain model of Axes.set_xlim / set_ylim for log scales after
  // unit conversion and nonpositive explicit-limit validation have passed.
  rule axisSetLogLimits(BOTTOM:Int, TOP:Int, MINPOS:Int)
    => limitRangeForLog(logNonsingular(BOTTOM, TOP, MINPOS, true, true),
                        MINPOS)
    requires BOTTOM >Int 0 andBool TOP >Int 0

  rule isInverted(pair(LOW:Int, HIGH:Int)) => HIGH <Int LOW
endmodule

