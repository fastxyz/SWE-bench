module MINI-PYTHON-MODEL-TO-DICT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX
  imports MAP-SYNTAX
  imports K-SYNTAX

  syntax NameList ::= ".Names"
                    | "nameCons" "(" String "," NameList ")"

  syntax FieldsOpt ::= "noneFields"
                     | "someFields" "(" NameList ")"

  syntax ExcludeOpt ::= "noneExclude"
                      | "someExclude" "(" NameList ")"

  syntax Field ::= "field" "(" String "," Bool "," KItem ")"

  syntax FieldSeq ::= ".Fields"
                    | "fieldCons" "(" Field "," FieldSeq ")"

  syntax Result ::= "result" "(" Map "," NameList ")"

  syntax Cmd ::= "model_to_dict" "(" FieldsOpt "," ExcludeOpt "," FieldSeq ")"
               | "filterFields" "(" FieldsOpt "," ExcludeOpt "," FieldSeq "," Map "," NameList ")"

  syntax KResult ::= Result
endmodule

module MINI-PYTHON-MODEL-TO-DICT
  imports MINI-PYTHON-MODEL-TO-DICT-SYNTAX
  imports BOOL
  imports STRING
  imports MAP

  configuration <k> $PGM:Cmd </k>

  syntax Bool ::= containsName(String, NameList) [function]
  rule containsName(N, .Names) => false
  rule containsName(N, nameCons(N, REST)) => true
  rule containsName(N, nameCons(M, REST)) => containsName(N, REST)
    requires N =/=String M

  syntax Bool ::= requested(FieldsOpt, String) [function]
  rule requested(noneFields, N) => true
  rule requested(someFields(NS), N) => containsName(N, NS)

  syntax Bool ::= excluded(ExcludeOpt, String) [function]
  rule excluded(noneExclude, N) => false
  rule excluded(someExclude(NS), N) => containsName(N, NS)

  syntax NameList ::= appendName(NameList, String) [function]
  rule appendName(.Names, N) => nameCons(N, .Names)
  rule appendName(nameCons(M, REST), N) => nameCons(M, appendName(REST, N))

  syntax Map ::= selectMap(FieldSeq, FieldsOpt, ExcludeOpt) [function]
  rule selectMap(.Fields, FIELDS, EXCLUDE) => .Map
  rule selectMap(fieldCons(field(N, false, V), REST), FIELDS, EXCLUDE)
    => selectMap(REST, FIELDS, EXCLUDE)
  rule selectMap(fieldCons(field(N, true, V), REST), FIELDS, EXCLUDE)
    => selectMap(REST, FIELDS, EXCLUDE)
    requires notBool requested(FIELDS, N) orBool excluded(EXCLUDE, N)
  rule selectMap(fieldCons(field(N, true, V), REST), FIELDS, EXCLUDE)
    => selectMap(REST, FIELDS, EXCLUDE) [N <- V]
    requires requested(FIELDS, N) andBool notBool excluded(EXCLUDE, N)

  syntax NameList ::= selectReads(FieldSeq, FieldsOpt, ExcludeOpt) [function]
  rule selectReads(.Fields, FIELDS, EXCLUDE) => .Names
  rule selectReads(fieldCons(field(N, false, V), REST), FIELDS, EXCLUDE)
    => selectReads(REST, FIELDS, EXCLUDE)
  rule selectReads(fieldCons(field(N, true, V), REST), FIELDS, EXCLUDE)
    => selectReads(REST, FIELDS, EXCLUDE)
    requires notBool requested(FIELDS, N) orBool excluded(EXCLUDE, N)
  rule selectReads(fieldCons(field(N, true, V), REST), FIELDS, EXCLUDE)
    => nameCons(N, selectReads(REST, FIELDS, EXCLUDE))
    requires requested(FIELDS, N) andBool notBool excluded(EXCLUDE, N)

  syntax Result ::= expectedFrom(FieldSeq, FieldsOpt, ExcludeOpt, Map, NameList) [function]
  rule expectedFrom(.Fields, FIELDS, EXCLUDE, DATA, READS)
    => result(DATA, READS)
  rule expectedFrom(fieldCons(field(N, false, V), REST), FIELDS, EXCLUDE, DATA, READS)
    => expectedFrom(REST, FIELDS, EXCLUDE, DATA, READS)
  rule expectedFrom(fieldCons(field(N, true, V), REST), FIELDS, EXCLUDE, DATA, READS)
    => expectedFrom(REST, FIELDS, EXCLUDE, DATA, READS)
    requires notBool requested(FIELDS, N) orBool excluded(EXCLUDE, N)
  rule expectedFrom(fieldCons(field(N, true, V), REST), FIELDS, EXCLUDE, DATA, READS)
    => expectedFrom(REST, FIELDS, EXCLUDE, DATA [N <- V], appendName(READS, N))
    requires requested(FIELDS, N) andBool notBool excluded(EXCLUDE, N)

  syntax Result ::= expectedResult(FieldSeq, FieldsOpt, ExcludeOpt) [function]
  rule expectedResult(FS, FIELDS, EXCLUDE)
    => expectedFrom(FS, FIELDS, EXCLUDE, .Map, .Names)

  rule <k> model_to_dict(FIELDS, EXCLUDE, FS)
        => filterFields(FIELDS, EXCLUDE, FS, .Map, .Names)
       ... </k>

  rule <k> filterFields(FIELDS, EXCLUDE, .Fields, DATA, READS)
        => result(DATA, READS)
       ... </k>

  rule <k> filterFields(FIELDS, EXCLUDE, fieldCons(field(N, false, V), REST), DATA, READS)
        => filterFields(FIELDS, EXCLUDE, REST, DATA, READS)
       ... </k>

  rule <k> filterFields(FIELDS, EXCLUDE, fieldCons(field(N, true, V), REST), DATA, READS)
        => filterFields(FIELDS, EXCLUDE, REST, DATA, READS)
       ... </k>
    requires notBool requested(FIELDS, N) orBool excluded(EXCLUDE, N)

  rule <k> filterFields(FIELDS, EXCLUDE, fieldCons(field(N, true, V), REST), DATA, READS)
        => filterFields(FIELDS, EXCLUDE, REST, DATA [N <- V], appendName(READS, N))
       ... </k>
    requires requested(FIELDS, N) andBool notBool excluded(EXCLUDE, N)
endmodule
