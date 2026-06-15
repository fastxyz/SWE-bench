requires "mini-itrs-transform.k"

module ITRS-TRANSFORM-SPEC
  imports MINI-ITRS-TRANSFORM

  claim <k> originShift(P:Vec, Lsrc:Vec, Ldst:Vec) => P2:Vec ...</k>
        ensures add(P2, Ldst) ==K add(P, Lsrc)

  claim <k> mismatchWarn(T1:Int, T2:Int) => true ...</k>
        requires T1 =/=Int T2

  claim <k> mismatchWarn(T:Int, T:Int) => false ...</k>
endmodule
