module MINI-PYTHON-SYNTAX
  imports BOOL-SYNTAX

  // Abstract object state for the audited public API slice:
  // rcvcv(StoreFlag, CvIsNone, CvValuesPresent).
  syntax Obj ::= rcvcv(Bool, Bool, Bool)
  syntax Error ::= incompatibleCV
  syntax Result ::= Obj | Error

  syntax KItem ::= constructRidgeClassifierCV(Bool, Bool)
                 | fitRidgeClassifierCV(Obj)
  syntax KResult ::= Result
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports BOOL

  configuration <k> $PGM:K </k>

  // Constructor keyword binding and delegation to _BaseRidgeCV.__init__.
  rule <k> constructRidgeClassifierCV(STORE:Bool, CVNONE:Bool)
        => rcvcv(STORE, CVNONE, false) ... </k>

  // _BaseRidgeCV.fit with cv=None and store_cv_values=True copies cv_values_.
  rule <k> fitRidgeClassifierCV(rcvcv(true, true, false))
        => rcvcv(true, true, true) ... </k>

  // _BaseRidgeCV.fit with store_cv_values=False has no cv_values_ obligation.
  rule <k> fitRidgeClassifierCV(rcvcv(false, CVNONE:Bool, false))
        => rcvcv(false, CVNONE, false) ... </k>

  // Existing documented incompatibility: cv != None and store_cv_values=True.
  rule <k> fitRidgeClassifierCV(rcvcv(true, false, false))
        => incompatibleCV ... </k>
endmodule
