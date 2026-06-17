module MINI-KAHANE-PREFIX-SYNTAX
  imports BOOL-SYNTAX

  syntax Idx ::= "rho" | "sigma" | "alpha" | "beta" | "mu" | "nu"

  syntax Idxs ::= ".Idxs"
                | "idx" "(" Idx "," Idxs ")" [klabel(idxCons)]

  syntax Branches ::= ".Branches"
                    | "branch" "(" Idxs "," Branches ")" [klabel(branchCons)]

  syntax Branches ::= restoreLeading(Idxs, Branches) [function]
                    | legacyRestoreLeading(Idxs, Branches) [function]
                    | restoreBranchesFixed(Idxs, Branches) [function]
                    | restoreBranchesLegacy(Idxs, Branches) [function]
                    | mapPrefix(Idxs, Branches) [function]

  syntax Idxs ::= append(Idxs, Idxs) [function]
                | restoreOneFixed(Idxs, Idxs) [function]
                | restoreOneLegacy(Idxs, Idxs) [function]
                | init(Idxs) [function]

  syntax Idx ::= last(Idxs) [function]
  syntax Bool ::= isEmpty(Idxs) [function]

  syntax KResult ::= Branches
endmodule

module MINI-KAHANE-PREFIX
  imports MINI-KAHANE-PREFIX-SYNTAX
  imports BOOL

  configuration <k> $PGM:Branches </k>

  rule isEmpty(.Idxs) => true
  rule isEmpty(idx(_:Idx, _:Idxs)) => false

  rule append(.Idxs, XS:Idxs) => XS
  rule append(idx(X:Idx, XS:Idxs), YS:Idxs) => idx(X, append(XS, YS))

  rule last(idx(X:Idx, .Idxs)) => X
  rule last(idx(_:Idx, XS:Idxs)) => last(XS)
    requires notBool isEmpty(XS)

  rule init(idx(_:Idx, .Idxs)) => .Idxs
  rule init(idx(X:Idx, XS:Idxs)) => idx(X, init(XS))
    requires notBool isEmpty(XS)

  // V1 behavior: iterate from the last prefix element toward the first, and
  // insert each element at the front of the branch.
  rule restoreOneFixed(.Idxs, RI:Idxs) => RI
  rule restoreOneFixed(P:Idxs, RI:Idxs)
    => restoreOneFixed(init(P), idx(last(P), RI))
    requires notBool isEmpty(P)

  // Legacy behavior: iterate from the first prefix element toward the last,
  // and insert each element at the front of the branch. This reverses P.
  rule restoreOneLegacy(.Idxs, RI:Idxs) => RI
  rule restoreOneLegacy(idx(X:Idx, XS:Idxs), RI:Idxs)
    => restoreOneLegacy(XS, idx(X, RI))

  rule restoreBranchesFixed(_:Idxs, .Branches) => .Branches
  rule restoreBranchesFixed(P:Idxs, branch(RI:Idxs, REST:Branches))
    => branch(restoreOneFixed(P, RI), restoreBranchesFixed(P, REST))

  rule restoreBranchesLegacy(_:Idxs, .Branches) => .Branches
  rule restoreBranchesLegacy(P:Idxs, branch(RI:Idxs, REST:Branches))
    => branch(restoreOneLegacy(P, RI), restoreBranchesLegacy(P, REST))

  rule mapPrefix(_:Idxs, .Branches) => .Branches
  rule mapPrefix(P:Idxs, branch(RI:Idxs, REST:Branches))
    => branch(append(P, RI), mapPrefix(P, REST))

  rule restoreLeading(P:Idxs, BS:Branches) => restoreBranchesFixed(P, BS)
  rule legacyRestoreLeading(P:Idxs, BS:Branches) => restoreBranchesLegacy(P, BS)
endmodule
