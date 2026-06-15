module MINI-DJANGO-QUERY-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Field ::= concreteField(String)
                 | foreignKey(String, Field)
  syntax Col ::= col(Field, Field)        // target, output_field
  syntax Select ::= noSelect()
                  | oneSelect(Col)
                  | manySelect()
  syntax AnnSelect ::= noAnn()
                     | oneAnn(Field)
                     | manyAnn()
  syntax Query ::= query(Select, AnnSelect)
  syntax Lazy ::= lazyModel(Field, Int)
                | rawInt(Int)
  syntax Prep ::= prepared(Int)
                | typeError()

  syntax Exp ::= Field
               | Col
               | Query
               | Lazy
               | Prep
               | target(Col)              [function]
               | field(Col)               [function]
               | outputField(Query)        [function]
               | subqueryOutput(Query)     [function]
               | prepExact(Field, Lazy)    [function]

  syntax KResult ::= Field | Col | Query | Lazy | Prep | Int | Bool
endmodule

module MINI-DJANGO-QUERY
  imports MINI-DJANGO-QUERY-SYNTAX
  imports INT
  imports BOOL
  imports STRING

  configuration <k> $PGM:Exp </k>

  rule target(col(T:Field, _O:Field)) => T
  rule field(col(_T:Field, O:Field)) => O

  // V1 behavior: single selected columns expose Col.target.
  rule outputField(query(oneSelect(C:Col), _A:AnnSelect)) => target(C)
  rule outputField(query(noSelect(), oneAnn(F:Field))) => F

  // Subquery._resolve_output_field() delegates to query.output_field.
  rule subqueryOutput(Q:Query) => outputField(Q)

  // Relation-aware exact lookup normalizes a lazy model to its target value.
  rule prepExact(foreignKey(_Name:String, Target:Field), lazyModel(Target, PK:Int)) => prepared(PK)

  // The concrete-field path models the reported failure on a lazy model RHS.
  rule prepExact(concreteField(_Name:String), lazyModel(_ModelField:Field, _PK:Int)) => typeError()
  rule prepExact(concreteField(_Name:String), rawInt(PK:Int)) => prepared(PK)
endmodule
