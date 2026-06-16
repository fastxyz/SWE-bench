module MINI-CV-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX
  imports MAP-SYNTAX
  imports LIST-SYNTAX

  syntax Stmt ::= getFeatureNames
                | maybeValidate
                | validateVocabulary
                | checkVocabulary
                | returnFeatureNames
                | raise(Exception)

  syntax VocabParam ::= noneVocab
                      | iterable(List)
                      | mapping(Map)

  syntax Exception ::= notFittedError | valueError | noException
  syntax Result ::= noResult | featureList(List)

  syntax KResult ::= Bool | Int | Map | List | VocabParam | Exception | Result
endmodule

module MINI-CV
  imports MINI-CV-SYNTAX
  imports BOOL
  imports INT
  imports MAP
  imports LIST

  configuration
    <k> $PGM:Stmt </k>
    <cv-param> noneVocab </cv-param>
    <has-vocabulary> false </has-vocabulary>
    <vocabulary> .Map </vocabulary>
    <has-fixed> false </has-fixed>
    <fixed> false </fixed>
    <result> noResult </result>
    <exception> noException </exception>

  syntax Bool ::= validVocab(VocabParam) [function]
  syntax Bool ::= emptyVocab(Map) [function]
  syntax Map ::= normalizeVocab(VocabParam) [function]
  syntax List ::= orderByIndex(Map) [function]

  rule <k> getFeatureNames
        => maybeValidate ~> checkVocabulary ~> returnFeatureNames
       ... </k>

  rule <k> maybeValidate => validateVocabulary ... </k>
       <has-vocabulary> false </has-vocabulary>

  rule <k> maybeValidate => .K ... </k>
       <has-vocabulary> true </has-vocabulary>

  rule <k> validateVocabulary => .K ... </k>
       <cv-param> noneVocab </cv-param>
       <has-fixed> _ => true </has-fixed>
       <fixed> _ => false </fixed>

  rule <k> validateVocabulary => .K ... </k>
       <cv-param> P:VocabParam </cv-param>
       <has-vocabulary> false => true </has-vocabulary>
       <vocabulary> _ => normalizeVocab(P) </vocabulary>
       <has-fixed> _ => true </has-fixed>
       <fixed> _ => true </fixed>
    requires P =/=K noneVocab
     andBool validVocab(P)
     andBool notBool emptyVocab(normalizeVocab(P))

  rule <k> validateVocabulary => raise(valueError) ... </k>
       <cv-param> P:VocabParam </cv-param>
    requires P =/=K noneVocab
     andBool (notBool validVocab(P)
              orBool emptyVocab(normalizeVocab(P)))

  rule <k> checkVocabulary => raise(notFittedError) ... </k>
       <has-vocabulary> false </has-vocabulary>

  rule <k> checkVocabulary => raise(valueError) ... </k>
       <has-vocabulary> true </has-vocabulary>
       <vocabulary> V:Map </vocabulary>
    requires emptyVocab(V)

  rule <k> checkVocabulary => .K ... </k>
       <has-vocabulary> true </has-vocabulary>
       <vocabulary> V:Map </vocabulary>
    requires notBool emptyVocab(V)

  rule <k> returnFeatureNames => .K ... </k>
       <has-vocabulary> true </has-vocabulary>
       <vocabulary> V:Map </vocabulary>
       <result> noResult => featureList(orderByIndex(V)) </result>

  rule <k> raise(E:Exception) ~> _ => .K </k>
       <exception> noException => E </exception>

  rule <k> raise(E:Exception) => .K </k>
       <exception> noException => E </exception>
endmodule
