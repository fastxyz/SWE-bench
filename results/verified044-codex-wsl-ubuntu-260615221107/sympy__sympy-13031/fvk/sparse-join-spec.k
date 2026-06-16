requires "mini-sparse-join.k"

module SPARSE-JOIN-SPEC
  imports MINI-SPARSE-JOIN
  imports INT
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_common_source: MatrixShaping.row_join adapts a left zero-column
  //   null matrix to the right operand's row count before joining.
  // - from_issue: sparse hstack must not discard compatible empty dimensions.
  claim
    <k> rowJoin(shape(R1:Int, 0), shape(R2:Int, C2:Int)) => shape(R2, C2) </k>
    requires R1 >=Int 0 andBool R2 >=Int 0 andBool C2 >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: row_join concatenates columns for matrices with equal rows.
  claim
    <k> rowJoin(shape(R:Int, C1:Int), shape(R:Int, C2:Int))
      => shape(R, C1 +Int C2) </k>
    requires R >=Int 0 andBool C1 >Int 0 andBool C2 >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_common_source: row_join raises ShapeError when rows differ outside
  //   the zero-column null-matrix adaptation.
  claim
    <k> rowJoin(shape(R1:Int, C1:Int), shape(R2:Int, C2:Int))
      => shapeError </k>
    requires R1 >=Int 0 andBool R2 >=Int 0 andBool C1 >Int 0
      andBool C2 >=Int 0 andBool R1 =/=Int R2
    [all-path]

  // SPEC-PROVENANCE:
  // - from_common_source: MatrixShaping.col_join adapts a left zero-row null
  //   matrix to the right operand's column count before joining.
  // - from_issue: sparse vstack must not discard compatible empty dimensions.
  claim
    <k> colJoin(shape(0, C1:Int), shape(R2:Int, C2:Int)) => shape(R2, C2) </k>
    requires C1 >=Int 0 andBool R2 >=Int 0 andBool C2 >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: col_join concatenates rows for matrices with equal columns.
  claim
    <k> colJoin(shape(R1:Int, C:Int), shape(R2:Int, C:Int))
      => shape(R1 +Int R2, C) </k>
    requires R1 >Int 0 andBool R2 >=Int 0 andBool C >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_common_source: col_join raises ShapeError when columns differ
  //   outside the zero-row null-matrix adaptation.
  claim
    <k> colJoin(shape(R1:Int, C1:Int), shape(R2:Int, C2:Int))
      => shapeError </k>
    requires R1 >Int 0 andBool R2 >=Int 0 andBool C1 >=Int 0
      andBool C2 >=Int 0 andBool C1 =/=Int C2
    [all-path]

  // SPEC-PROVENANCE:
  // - from_issue: hstack of 0xn matrices for n in range(4) should have shape
  //   (0, 6); generalized to any four nonnegative column counts.
  claim
    <k> hstackShapes(
          shape(0, C0:Int) ;
          shape(0, C1:Int) ;
          shape(0, C2:Int) ;
          shape(0, C3:Int) ;
          .Shapes)
      => shape(0, C0 +Int C1 +Int C2 +Int C3) </k>
    requires C0 >=Int 0 andBool C1 >=Int 0 andBool C2 >=Int 0
      andBool C3 >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_issue_hint: vstack of nx0 matrices for n in range(4) should have
  //   shape (6, 0); generalized to any four nonnegative row counts.
  claim
    <k> vstackShapes(
          shape(R0:Int, 0) ;
          shape(R1:Int, 0) ;
          shape(R2:Int, 0) ;
          shape(R3:Int, 0) ;
          .Shapes)
      => shape(R0 +Int R1 +Int R2 +Int R3, 0) </k>
    requires R0 >=Int 0 andBool R1 >=Int 0 andBool R2 >=Int 0
      andBool R3 >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_issue: hstack with a nonempty common row count already returns the
  //   accumulated width and must remain so.
  claim
    <k> hstackShapes(
          shape(R:Int, C0:Int) ;
          shape(R:Int, C1:Int) ;
          shape(R:Int, C2:Int) ;
          shape(R:Int, C3:Int) ;
          .Shapes)
      => shape(R, C0 +Int C1 +Int C2 +Int C3) </k>
    requires R >=Int 0 andBool C0 >=Int 0 andBool C1 >=Int 0
      andBool C2 >=Int 0 andBool C3 >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_common_source: compatible vstack should accumulate rows and
  //   preserve the common column count.
  claim
    <k> vstackShapes(
          shape(R0:Int, C:Int) ;
          shape(R1:Int, C:Int) ;
          shape(R2:Int, C:Int) ;
          shape(R3:Int, C:Int) ;
          .Shapes)
      => shape(R0 +Int R1 +Int R2 +Int R3, C) </k>
    requires R0 >=Int 0 andBool R1 >=Int 0 andBool R2 >=Int 0
      andBool R3 >=Int 0 andBool C >=Int 0
    [all-path]
endmodule
