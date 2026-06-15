module MINI-ASTROPY-TABLE-SYNTAX
  syntax Data ::= "plainStructuredNdarray"
                | "explicitNdarrayMixin"
                | "otherColumnData"

  syntax Result ::= "columnResult" "(" Data ")"
                  | "mixinResult" "(" Data ")"

  syntax Class ::= "ColumnClass"
                 | "NdarrayMixinClass"

  syntax KItem ::= "convert" "(" Data ")"
                 | "tableModuleNdarrayMixin"
endmodule

module MINI-ASTROPY-TABLE
  imports MINI-ASTROPY-TABLE-SYNTAX

  configuration <k> $PGM:K </k>

  // V2 conversion model for Table._convert_data_to_col:
  // a non-Column, non-mixin structured ndarray is normal column data.
  rule <k> convert(plainStructuredNdarray)
        => columnResult(plainStructuredNdarray) ... </k>

  // Existing explicit NdarrayMixin inputs remain mixins.
  rule <k> convert(explicitNdarrayMixin)
        => mixinResult(explicitNdarrayMixin) ... </k>

  // Other non-mixin column data is outside this issue and follows the normal
  // ColumnClass path.
  rule <k> convert(otherColumnData)
        => columnResult(otherColumnData) ... </k>

  // Compatibility model for astropy.table.table.NdarrayMixin.
  rule <k> tableModuleNdarrayMixin => NdarrayMixinClass ... </k>
endmodule
