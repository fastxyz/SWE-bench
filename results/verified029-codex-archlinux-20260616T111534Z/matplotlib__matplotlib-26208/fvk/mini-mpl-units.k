requires "domains.md"

module MINI-MPL-UNITS-SYNTAX
  imports K
  imports BOOL

  syntax Action ::= "shareX" | "shareY" | "plotAx2Strings"
  syntax DataLim ::= "valid" | "null"
  syntax Converter ::= "noneConverter" | "categoryConverter"
  syntax Unit ::= "noUnit" | "unit1"
endmodule

module MINI-MPL-UNITS
  imports MINI-MPL-UNITS-SYNTAX
  imports BOOL

  configuration
    <k> $PGM:K </k>
    <ax1XHasUnits> false </ax1XHasUnits>
    <ax1XConverter> noneConverter </ax1XConverter>
    <ax1XUnits> noUnit </ax1XUnits>
    <ax1YHasUnits> false </ax1YHasUnits>
    <ax1YConverter> noneConverter </ax1YConverter>
    <ax1YUnits> noUnit </ax1YUnits>
    <ax1DataLim> null </ax1DataLim>
    <ax1RelimCount> false </ax1RelimCount>
    <ax2XHasUnits> false </ax2XHasUnits>
    <ax2XConverter> noneConverter </ax2XConverter>
    <ax2XUnits> noUnit </ax2XUnits>
    <ax2YHasUnits> false </ax2YHasUnits>
    <ax2YConverter> noneConverter </ax2YConverter>
    <ax2YUnits> noUnit </ax2YUnits>
    <ax2DataLim> null </ax2DataLim>

  // V1 sharex rule: a receiver with no x units inherits the shared x units.
  rule <k> shareX => .K ... </k>
       <ax1XHasUnits> H1:Bool </ax1XHasUnits>
       <ax1XConverter> C1:Converter </ax1XConverter>
       <ax1XUnits> U1:Unit </ax1XUnits>
       <ax2XHasUnits> false => H1 </ax2XHasUnits>
       <ax2XConverter> _:Converter => C1 </ax2XConverter>
       <ax2XUnits> _:Unit => U1 </ax2XUnits>

  // Receiver already has units: V1 leaves them unchanged.
  rule <k> shareX => .K ... </k>
       <ax2XHasUnits> true </ax2XHasUnits>

  // Symmetric y-axis rule.
  rule <k> shareY => .K ... </k>
       <ax1YHasUnits> H1:Bool </ax1YHasUnits>
       <ax1YConverter> C1:Converter </ax1YConverter>
       <ax1YUnits> U1:Unit </ax1YUnits>
       <ax2YHasUnits> false => H1 </ax2YHasUnits>
       <ax2YConverter> _:Converter => C1 </ax2YConverter>
       <ax2YUnits> _:Unit => U1 </ax2YUnits>

  rule <k> shareY => .K ... </k>
       <ax2YHasUnits> true </ax2YHasUnits>

  // Plotting string x data on ax2 after sharex. If ax2 already has x units,
  // no shared set_units callback occurs, so ax1RelimCount and ax1DataLim frame.
  rule <k> plotAx2Strings => .K ... </k>
       <ax2XHasUnits> true </ax2XHasUnits>
       <ax1DataLim> DL:DataLim => DL </ax1DataLim>
       <ax1RelimCount> R:Bool => R </ax1RelimCount>
       <ax2DataLim> _:DataLim => valid </ax2DataLim>
endmodule
