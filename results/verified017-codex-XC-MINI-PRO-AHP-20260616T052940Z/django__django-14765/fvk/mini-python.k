module MINI-PROJECTSTATE-SYNTAX
  imports BOOL-SYNTAX

  syntax RealAppsShape ::= "none"
                         | "emptySet"
                         | "nonEmptySet"
                         | "nonSet"

  syntax ObjValue ::= "unset"
                    | "modelsValue"
                    | "emptySetValue"
                    | "sameEmptySet"
                    | "sameNonEmptySet"
                    | "falseValue"
                    | "noneValue"
                    | "ok"
                    | "assertionError"

  syntax Stmt ::= "initProjectState" "(" RealAppsShape ")"
                | "finishOk"
                | "finishAssert"
endmodule

module MINI-PROJECTSTATE
  imports MINI-PROJECTSTATE-SYNTAX
  imports K-EQUAL

  configuration
    <k> $PGM:Stmt </k>
    <models> unset </models>
    <realAppsAttr> unset </realAppsAttr>
    <isDelayed> unset </isDelayed>
    <relations> unset </relations>
    <result> unset </result>

  // Models the V1 constructor branch:
  // self.models = models or {}
  // if real_apps is None:
  //     self.real_apps = set()
  // else:
  //     assert isinstance(real_apps, set)
  //     self.real_apps = real_apps
  rule <k> initProjectState(none) => finishOk </k>
       <models> unset => modelsValue </models>
       <realAppsAttr> unset => emptySetValue </realAppsAttr>

  rule <k> initProjectState(emptySet) => finishOk </k>
       <models> unset => modelsValue </models>
       <realAppsAttr> unset => sameEmptySet </realAppsAttr>

  rule <k> initProjectState(nonEmptySet) => finishOk </k>
       <models> unset => modelsValue </models>
       <realAppsAttr> unset => sameNonEmptySet </realAppsAttr>

  rule <k> initProjectState(nonSet) => finishAssert </k>
       <models> unset => modelsValue </models>

  rule <k> finishOk => .K </k>
       <isDelayed> unset => falseValue </isDelayed>
       <relations> unset => noneValue </relations>
       <result> unset => ok </result>

  rule <k> finishAssert => .K </k>
       <result> unset => assertionError </result>
endmodule

