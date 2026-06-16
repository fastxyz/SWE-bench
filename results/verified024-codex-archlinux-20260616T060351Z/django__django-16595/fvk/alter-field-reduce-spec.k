requires "mini-migration-optimizer.k"

module ALTER-FIELD-REDUCE-SPEC
  imports MINI-MIGRATION-OPTIMIZER
  imports BOOL
  imports STRING

  // SPEC-PROVENANCE:
  // - from_prompt: "AlterField.reduce does not consider the case where
  //   operation is also an AlterField" => same-field AlterField pairs must
  //   reduce.
  // - from_prompt: "return [operation]" => the later AlterField is retained
  //   unchanged, including its field and preserve_default payload.
  claim
    <k> reduceAlter(alter(M:String, N:String, F1:Field, P1:Bool),
                    alter(M, N, F2:Field, P2:Bool))
      => ops(alter(M, N, F2, P2) ; .Ops) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: optimizer.optimize(operations[1:], "books") should not
  //   leave all three AlterField operations unreduced.
  // - from_optimizer: optimize() repeats optimize_inner() until stable.
  claim
    <k> optimizeAlterChain(
          alter(M:String, N:String, F1:Field, P1:Bool) ;
          alter(M, N, F2:Field, P2:Bool) ;
          alter(M, N, F3:Field, P3:Bool) ;
          .Ops
        )
      => alter(M, N, F3, P3) ; .Ops </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: is_same_field_operation() requires same model and field
  //   comparison keys.
  // - frame_condition: different model or field AlterField pairs are not
  //   reduced by the new V1 branch.
  claim
    <k> reduceAlter(alter(M1:String, N1:String, F1:Field, P1:Bool),
                    alter(M2:String, N2:String, F2:Field, P2:Bool))
      => pass(false) </k>
    requires notBool (M1 ==String M2 andBool N1 ==String N2)
    [all-path]
endmodule
