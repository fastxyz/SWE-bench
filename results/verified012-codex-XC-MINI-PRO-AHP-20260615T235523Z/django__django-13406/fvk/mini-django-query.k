module MINI-DJANGO-QUERY-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Iterable ::= ModelIterable
                    | ValuesIterable
                    | ValuesListIterable
                    | FlatValuesListIterable
                    | NamedValuesListIterable

  syntax MaybeIterable ::= noIterable | someIterable(Iterable)
  syntax Fields ::= fields(String)
  syntax MaybeFields ::= noFields | someFields(Fields)

  syntax Query ::= query(Bool, MaybeIterable, MaybeFields, Fields)
  syntax QuerySet ::= qs(Iterable, MaybeFields, Query)

  syntax Mode ::= tupleMode | flatMode | namedMode
  syntax Op ::= assignQuery(QuerySet, Query)
              | makeValues(Fields)
              | makeValuesList(Fields, Mode)

  syntax KResult ::= Iterable | MaybeIterable | Fields | MaybeFields | Query | QuerySet | Mode
endmodule

module MINI-DJANGO-QUERY
  imports MINI-DJANGO-QUERY-SYNTAX
  imports BOOL

  configuration <k> $PGM:Op </k>

  rule <k> makeValues(F:Fields)
        => query(true, someIterable(ValuesIterable), someFields(F), F)
       </k>

  rule <k> makeValuesList(F:Fields, tupleMode)
        => query(true, someIterable(ValuesListIterable), someFields(F), F)
       </k>

  rule <k> makeValuesList(F:Fields, flatMode)
        => query(true, someIterable(FlatValuesListIterable), someFields(F), F)
       </k>

  rule <k> makeValuesList(F:Fields, namedMode)
        => query(true, someIterable(NamedValuesListIterable), someFields(F), F)
       </k>

  rule <k> assignQuery(qs(_OLDI:Iterable, _OLDF:MaybeFields, _OLDQ:Query),
                       query(true, someIterable(I:Iterable), someFields(F:Fields), SEL:Fields))
        => qs(I, someFields(F), query(true, someIterable(I), someFields(F), SEL))
       </k>

  rule <k> assignQuery(qs(_OLDI:Iterable, _OLDF:MaybeFields, _OLDQ:Query),
                       query(true, noIterable, noFields, SEL:Fields))
        => qs(ValuesIterable, someFields(SEL), query(true, noIterable, noFields, SEL))
       </k>

  rule <k> assignQuery(qs(OLDI:Iterable, OLDF:MaybeFields, _OLDQ:Query),
                       query(false, MI:MaybeIterable, MF:MaybeFields, SEL:Fields))
        => qs(OLDI, OLDF, query(false, MI, MF, SEL))
       </k>
endmodule

