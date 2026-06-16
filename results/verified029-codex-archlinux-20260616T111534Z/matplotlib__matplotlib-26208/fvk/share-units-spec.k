requires "mini-mpl-units.k"

module SHARE-UNITS-SPEC
  imports MINI-MPL-UNITS

  // SPEC-PROVENANCE:
  // - E1/E2: The original axes' dataLim must remain valid after plotting on
  //   the twin because no data was added to the original axes.
  // - E3: The defect is a late unit-machinery update on a shared categorical
  //   axis.
  // - E4: Sharing an axis includes sharing axis information.
  claim
    <k> shareX ~> plotAx2Strings => .K </k>
    <ax1XHasUnits> true </ax1XHasUnits>
    <ax1XConverter> categoryConverter </ax1XConverter>
    <ax1XUnits> unit1 </ax1XUnits>
    <ax1DataLim> valid => valid </ax1DataLim>
    <ax1RelimCount> false => false </ax1RelimCount>
    <ax2XHasUnits> false => true </ax2XHasUnits>
    <ax2XConverter> noneConverter => categoryConverter </ax2XConverter>
    <ax2XUnits> noUnit => unit1 </ax2XUnits>
    <ax2DataLim> null => valid </ax2DataLim>
    [all-path]

  // SPEC-PROVENANCE:
  // - E4 plus axis symmetry: sharey has the same unit-inheritance obligation
  //   for a fresh receiving y-axis.
  claim
    <k> shareY => .K </k>
    <ax1YHasUnits> true </ax1YHasUnits>
    <ax1YConverter> categoryConverter </ax1YConverter>
    <ax1YUnits> unit1 </ax1YUnits>
    <ax2YHasUnits> false => true </ax2YHasUnits>
    <ax2YConverter> noneConverter => categoryConverter </ax2YConverter>
    <ax2YUnits> noUnit => unit1 </ax2YUnits>
    [all-path]

  // SPEC-PROVENANCE:
  // - F3/PO5: A receiver that already has units is framed for compatibility.
  claim
    <k> shareX => .K </k>
    <ax2XHasUnits> true => true </ax2XHasUnits>
    <ax2XConverter> categoryConverter => categoryConverter </ax2XConverter>
    <ax2XUnits> unit1 => unit1 </ax2XUnits>
    [all-path]
endmodule
