requires "mini-python.k"

module INDEX-COLUMNS-SPEC
  imports MINI-PYTHON
  imports STRING
  imports BOOL

  // SPEC-PROVENANCE:
  // - INT-2 and INT-4: empty suffix tokens are valid ascending/default order.
  // - PO-2: empty suffixes must be omitted for normal columns.
  claim
    <k> emitPlain(C:String, "") => "\"" +String C +String "\"" </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - INT-1 and INT-4: a non-empty order suffix such as DESC must be separated.
  // - PO-1: quoted column and non-empty suffix are distinct SQL tokens.
  claim
    <k> emitPlain(C:String, S:String)
        => "\"" +String C +String "\"" +String " " +String S
    </k>
    requires S =/=String ""
    [all-path]

  // SPEC-PROVENANCE:
  // - INT-2, INT-4, and INT-5: opclass with empty order suffix has no trailing separator.
  // - PO-3: quoted column and opclass are distinct SQL tokens.
  claim
    <k> emitIndex(C:String, O:String, "")
        => "\"" +String C +String "\"" +String " " +String O
    </k>
    requires O =/=String ""
    [all-path]

  // SPEC-PROVENANCE:
  // - INT-3, INT-4, and INT-5: opclass plus descending order keeps all three tokens.
  // - PO-4: quoted column, opclass, and non-empty suffix are distinct SQL tokens.
  claim
    <k> emitIndex(C:String, O:String, S:String)
        => "\"" +String C +String "\"" +String " " +String O +String " " +String S
    </k>
    requires O =/=String "" andBool S =/=String ""
    [all-path]

  // PO-5 is discharged by source preservation: both Django __str__ methods retain
  // the outer ', '.join(...) over per-column renderings, and no signatures changed.
endmodule
