// Abstract mini-semantics for the Dataset.merge(DataArray) audit.
// Constructed, not machine-checked. This is intentionally smaller than Python:
// it preserves only the observable property under audit, namely whether
// dataset_merge_method passes a raw DataArray or a Dataset/mapping downstream.

module MINI-XARRAY-MERGE-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX

  syntax Obj ::= dataset(String)
               | dataArray(String)
               | unnamedDataArray
               | mapping(String)

  syntax OSet ::= ".OSet"
                | vars(Obj)
                | partialVars(Obj)

  syntax Priority ::= "none" | priority(Int)

  syntax ObjList ::= "[" "]"
                   | "[" Obj "," Obj "]"
                   | "[" Obj "," Obj "," Obj "]"

  syntax Result ::= core(ObjList, Priority)
                  | raises(String)
                  | legacyDatasetMerge(Obj, Obj, OSet)

  syntax Exp ::= toDataset(Obj)
               | datasetMerge(Obj, Obj, OSet)

  syntax KResult ::= Obj | OSet | Priority | Result
endmodule

module MINI-XARRAY-MERGE
  imports MINI-XARRAY-MERGE-SYNTAX

  configuration <k> $PGM:K </k>

  rule <k> toDataset(dataArray(N)) => dataset(N) </k>
  rule <k> toDataset(unnamedDataArray) => raises("unnamed-dataarray") </k>

  rule <k> datasetMerge(DS, dataArray(N), .OSet)
        => core([DS, dataset(N)], none)
       </k>

  rule <k> datasetMerge(DS, dataArray(N), vars(dataset(N)))
        => core([DS, dataset(N)], priority(1))
       </k>

  rule <k> datasetMerge(DS, dataArray(N), partialVars(dataset(N)))
        => core([DS, mapping("no-overwrite"), mapping("overwrite")], priority(2))
       </k>

  rule <k> datasetMerge(DS, unnamedDataArray, OW)
        => raises("unnamed-dataarray")
       </k>

  rule <k> datasetMerge(DS, dataset(N), OW)
        => legacyDatasetMerge(DS, dataset(N), OW)
       </k>

  rule <k> datasetMerge(DS, mapping(N), OW)
        => legacyDatasetMerge(DS, mapping(N), OW)
       </k>
endmodule
