requires "mini-django-query.k"

module DJANGO-QUERYSET-QUERY-SPEC
  imports MINI-DJANGO-QUERY

  // SPEC-PROVENANCE:
  // - E2/E4: values() must preserve dict-shaped results through query restore.
  // - source: query.py writes ValuesIterable and _fields onto the Query.
  // CLAIM: VALUES-MARKS
  claim
    <k> makeValues(F:Fields)
     => query(true, someIterable(ValuesIterable), someFields(F), F)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: tuple-mode values_list() must preserve ValuesListIterable.
  // CLAIM: VALUES-LIST-TUPLE-MARKS
  claim
    <k> makeValuesList(F:Fields, tupleMode)
     => query(true, someIterable(ValuesListIterable), someFields(F), F)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: flat values_list() must preserve FlatValuesListIterable.
  // CLAIM: VALUES-LIST-FLAT-MARKS
  claim
    <k> makeValuesList(F:Fields, flatMode)
     => query(true, someIterable(FlatValuesListIterable), someFields(F), F)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: named values_list() must preserve NamedValuesListIterable.
  // CLAIM: VALUES-LIST-NAMED-MARKS
  claim
    <k> makeValuesList(F:Fields, namedMode)
     => query(true, someIterable(NamedValuesListIterable), someFields(F), F)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E3/E6: qs.query = query is the documented restore point.
  // - E4/E5: marked selected queries must restore exact iterable class.
  // CLAIM: ASSIGN-MARKED-SELECT
  claim
    <k> assignQuery(qs(OLDI:Iterable, OLDF:MaybeFields, OLDQ:Query),
                    query(true, someIterable(I:Iterable), someFields(F:Fields), SEL:Fields))
     => qs(I, someFields(F), query(true, someIterable(I), someFields(F), SEL))
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1: selected values rows must not be routed through ModelIterable.
  // - F4/PO7: exact values_list mode is underdetermined without a marker.
  // CLAIM: ASSIGN-UNMARKED-SELECT
  claim
    <k> assignQuery(qs(OLDI:Iterable, OLDF:MaybeFields, OLDQ:Query),
                    query(true, noIterable, noFields, SEL:Fields))
     => qs(ValuesIterable, someFields(SEL), query(true, noIterable, noFields, SEL))
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - compatibility: non-selected query assignment is outside the reported
  //   values()/values_list() bug and should preserve existing frame behavior.
  // CLAIM: ASSIGN-NONSELECT-FRAME
  claim
    <k> assignQuery(qs(OLDI:Iterable, OLDF:MaybeFields, OLDQ:Query),
                    query(false, MI:MaybeIterable, MF:MaybeFields, SEL:Fields))
     => qs(OLDI, OLDF, query(false, MI, MF, SEL))
    </k>
    [all-path]
endmodule
