module MINI-XARRAY-COPY-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax DType ::= "object"
                 | "unicode" "(" Int ")"
                 | "otherDType" "(" Int ")"

  syntax Adapter ::= "adapter" "(" DType "," DType ")"
  syntax IndexVar ::= "indexVar" "(" Adapter ")"

  syntax Exp ::= IndexVar
               | DType
               | "copyIndexVariable" "(" IndexVar "," Bool ")"
               | "adapterDType" "(" Exp ")" [strict]

  syntax KResult ::= IndexVar | DType
endmodule

module MINI-XARRAY-COPY
  imports MINI-XARRAY-COPY-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>

  // Model of V1 IndexVariable.copy(data=None):
  // - the first DType is the dtype exposed by the underlying pandas.Index;
  // - the second DType is the explicit dtype carried by PandasIndexAdapter.
  // V1 deep-copy rebuilds the adapter around a copied pandas index but passes
  // through the old adapter dtype.
  rule <k> copyIndexVariable(indexVar(adapter(PANDAS:DType, ADAPTER:DType)), true)
        => indexVar(adapter(PANDAS, ADAPTER)) ... </k>

  // Shallow copy reuses the adapter, so both dtype fields are unchanged.
  rule <k> copyIndexVariable(indexVar(adapter(PANDAS:DType, ADAPTER:DType)), false)
        => indexVar(adapter(PANDAS, ADAPTER)) ... </k>

  rule <k> adapterDType(indexVar(adapter(_:DType, ADAPTER:DType)))
        => ADAPTER ... </k>
endmodule
