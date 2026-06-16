// Constructed, not machine-checked.
// Minimal abstract K skeleton for the to_unstacked_dataset reconstruction step.

module MINI-XARRAY-UNSTACK-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX
  imports LIST-SYNTAX
  imports MAP-SYNTAX

  syntax Arr ::= arr(List, Map)              // dims, coordinate map
  syntax Dataset ::= dataset(Map)            // variable label -> Arr
  syntax Outcome ::= ok(Dataset) | valueError
  syntax Step ::= toUnstackedDataset(Arr, String, String)
                | buildVars(List, Arr, String, String, Map)
                | finish(Dataset)

  syntax Bool ::= isMultiIndex(Arr, String) [function]
  syntax List ::= levelLabels(Arr, String, String) [function]
  syntax Arr ::= selectLevel(Arr, String, String, String) [function]
               | squeezeDims(Arr, List) [function]
               | dropVars(Arr, List) [function]
  syntax List ::= dimsToSqueeze(Arr, String, String, List) [function]
                | consumedSingletonDim(Arr, String) [function]
                | missingSingletonDims(Arr, String, List) [function]
  syntax Map ::= putVar(Map, String, Arr) [function]
endmodule

module MINI-XARRAY-UNSTACK
  imports MINI-XARRAY-UNSTACK-SYNTAX
  imports BOOL
  imports LIST
  imports MAP

  configuration <k> $PGM:Step </k> <out> valueError </out>

  rule <k> toUnstackedDataset(A:Arr, DIM:String, VAR:String)
        => buildVars(levelLabels(A, DIM, VAR), A, DIM, VAR, .Map) ... </k>
    requires isMultiIndex(A, DIM)

  rule <k> toUnstackedDataset(A:Arr, DIM:String, VAR:String)
        => finish(dataset(.Map)) ... </k>
       <out> _ => valueError </out>
    requires notBool isMultiIndex(A, DIM)

  rule <k> buildVars(.List, _A:Arr, _DIM:String, _VAR:String, ACC:Map)
        => finish(dataset(ACC)) ... </k>

  // Abstracts one loop iteration in the Python implementation:
  // select variable label K, squeeze only consumed/missing dimensions,
  // then drop consumed coordinate variables before inserting into the dataset.
  rule <k> buildVars(ListItem(K:String) REST:List, A:Arr, DIM:String, VAR:String, ACC:Map)
        => buildVars(
             REST,
             A,
             DIM,
             VAR,
             putVar(
               ACC,
               K,
               dropVars(
                 squeezeDims(selectLevel(A, VAR, K, DIM),
                             dimsToSqueeze(selectLevel(A, VAR, K, DIM), DIM, VAR, REST)),
                 ListItem(DIM) ListItem(VAR))))
           ... </k>

  rule dimsToSqueeze(A:Arr, DIM:String, VAR:String, LEVELS:List)
        => consumedSingletonDim(A, DIM) missingSingletonDims(A, VAR, LEVELS)
endmodule
