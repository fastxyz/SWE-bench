module MINI-DJANGO-YEARLOOKUP-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax FieldKind ::= date | datetime
  syntax LookupKind ::= year | isoYear

  syntax Date ::= jan1(Int) | dec31(Int)
                | isoStart(Int) | isoEnd(Int) | maxDate
  syntax DateTime ::= dtStartOf(Date) | dtEndOf(Date) | maxDateTime

  syntax Bounds ::= dateBounds(Date, Date)
                  | datetimeBounds(DateTime, DateTime)

  syntax Exp ::= route(FieldKind, LookupKind, Int)
               | calendarDateBounds(Int)
               | calendarDateTimeBounds(Int)
               | isoDateBounds(Int)
               | isoDateTimeBounds(Int)

  syntax KResult ::= Bounds
endmodule

module MINI-DJANGO-YEARLOOKUP
  imports MINI-DJANGO-YEARLOOKUP-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>

  rule <k> route(date, year, Y) => calendarDateBounds(Y) ... </k>
  rule <k> route(datetime, year, Y) => calendarDateTimeBounds(Y) ... </k>
  rule <k> route(date, isoYear, Y) => isoDateBounds(Y) ... </k>
  rule <k> route(datetime, isoYear, Y) => isoDateTimeBounds(Y) ... </k>

  rule <k> calendarDateBounds(Y) => dateBounds(jan1(Y), dec31(Y)) ... </k>
  rule <k> calendarDateTimeBounds(Y) =>
       datetimeBounds(dtStartOf(jan1(Y)), dtEndOf(dec31(Y))) ... </k>

  rule <k> isoDateBounds(Y) => dateBounds(isoStart(Y), isoEnd(Y)) ... </k>
    requires Y =/=Int 9999
  rule <k> isoDateBounds(9999) => dateBounds(isoStart(9999), maxDate) ... </k>

  rule <k> isoDateTimeBounds(Y) =>
       datetimeBounds(dtStartOf(isoStart(Y)), dtEndOf(isoEnd(Y))) ... </k>
    requires Y =/=Int 9999
  rule <k> isoDateTimeBounds(9999) =>
       datetimeBounds(dtStartOf(isoStart(9999)), maxDateTime) ... </k>
endmodule
