// Constructed FVK artifact for scikit-learn__scikit-learn-14629.
// This is a minimal, property-complete fragment for the audited code path:
// MultiOutputClassifier.fit / partial_fit setting classes_, and
// cross_val_predict(method="predict_proba") reading classes_[i].
// It is constructed, not machine-checked in this environment.

module MINI-PYTHON-MULTIOUTPUT-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX
  imports LIST-SYNTAX
  imports MAP-SYNTAX

  syntax Stmt ::= "moc_fit" "(" Id "," List ")"
                | "moc_partial_fit" "(" Id "," List ")"
                | "cvp_predict_proba" "(" Id "," List ")"

  syntax MocState ::= "MOC" "(" List "," List ")"  // estimators_, classes_
  syntax EstState ::= "EST" "(" List ")"           // estimator.classes_
  syntax KResult ::= MocState | EstState | List
endmodule

module MINI-PYTHON-MULTIOUTPUT
  imports MINI-PYTHON-MULTIOUTPUT-SYNTAX
  imports INT
  imports BOOL
  imports LIST
  imports MAP

  configuration
    <k> $PGM:Stmt </k>
    <store> .Map </store>

  syntax List ::= estimatorsFromClasses(List) [function]
  syntax List ::= classesFromEstimators(List) [function]
  syntax List ::= enforceListOrder(List, List) [function]

  rule estimatorsFromClasses(.List) => .List
  rule estimatorsFromClasses(ListItem(CS:List) REST:List)
    => ListItem(EST(CS)) estimatorsFromClasses(REST)

  rule classesFromEstimators(.List) => .List
  rule classesFromEstimators(ListItem(EST(CS:List)) REST:List)
    => ListItem(CS) classesFromEstimators(REST)

  // Represents MultiOutputClassifier.fit: the inherited fit constructs one
  // fitted estimator per output; V1 then assigns self.classes_ from those
  // fitted estimators.
  rule <k> moc_fit(SELF:Id, CS:List) => .K ... </k>
       <store> STORE:Map => STORE
         [ SELF <- MOC(estimatorsFromClasses(CS),
                       classesFromEstimators(estimatorsFromClasses(CS))) ]
       </store>

  // Represents MultiOutputClassifier.partial_fit after the delegated
  // incremental fit succeeds.
  rule <k> moc_partial_fit(SELF:Id, CS:List) => .K ... </k>
       <store> STORE:Map => STORE
         [ SELF <- MOC(estimatorsFromClasses(CS),
                       classesFromEstimators(estimatorsFromClasses(CS))) ]
       </store>

  // Represents the list-valued prediction branch of _fit_and_predict:
  // each prediction block is reordered using estimator.classes_[i_label].
  rule <k> cvp_predict_proba(SELF:Id, PREDS:List) => .K ... </k>
       <store> ... SELF |-> MOC(ESTS:List, CLS:List)
                 result |-> (_ => enforceListOrder(CLS, PREDS)) ... </store>
endmodule
