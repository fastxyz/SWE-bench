requires "mini-python-marks.k"

module MARK-MRO-SPEC
  imports MINI-PYTHON-MARKS

  // SPEC-PROVENANCE:
  // - E1/E2: the issue expects both foo and bar on TestDings(Foo, Bar).
  // - E3: class lookup should walk the MRO.
  // - Code model: V1 flattens reversed(__mro__), represented here as
  //   [objectClass, baseClass, barClass, fooClass, testDings].
  claim
    <k>
      getClassMarks(
        objectClass , baseClass , barClass , fooClass , testDings , .Classes,
        fooClass |-> fooMark , .Marks ;
        barClass |-> barMark , .Marks ;
        .ClassMarks
      )
    => barMark , fooMark , .Marks
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E6: subclass marks must not mutate bases or siblings.
  // - Code model: store_mark uses consider_mro=False.
  claim
    <k>
      storeDirect(
        subClass,
        subMark,
        baseClass |-> baseMark , .Marks ;
        .ClassMarks
      )
    => subMark , .Marks
    </k>
    [all-path]
endmodule
