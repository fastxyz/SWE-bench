module MINI-COLUMN-TRANSFORMER-SYNTAX
  imports BOOL-SYNTAX

  syntax Transform ::= "none" | "default" | "pandas"
  syntax Kind ::= "estimator" | "sentinel"
  syntax Output ::= "unset" | "outDefault" | "outPandas"
  syntax Branch ::= "useArray" | "usePandas"

  // ct(explicitOutput, remainderKind, remainderOutput, selfOutput)
  syntax CT ::= "ct" "(" Output "," Kind "," Output "," Output ")"

  syntax CT ::= setOutput(CT, Transform) [function]
  syntax CT ::= setExplicit(CT, Transform) [function]
  syntax CT ::= setRemainder(CT, Transform) [function]
  syntax Output ::= cloneRemainderOutput(CT) [function]
  syntax Branch ::= hstackBranch(Output, Output, Output) [function]
endmodule

module MINI-COLUMN-TRANSFORMER
  imports MINI-COLUMN-TRANSFORMER-SYNTAX
  imports BOOL

  // ColumnTransformer.set_output first configures self and explicit children,
  // then configures estimator-valued remainder.
  rule setOutput(ct(EXP, RK, REM, _), pandas)
    => setRemainder(setExplicit(ct(EXP, RK, REM, outPandas), pandas), pandas)
  rule setOutput(ct(EXP, RK, REM, _), default)
    => setRemainder(setExplicit(ct(EXP, RK, REM, outDefault), default), default)
  rule setOutput(ct(EXP, RK, REM, SELF), none)
    => setRemainder(setExplicit(ct(EXP, RK, REM, SELF), none), none)

  rule setExplicit(ct(_, RK, REM, SELF), pandas) => ct(outPandas, RK, REM, SELF)
  rule setExplicit(ct(_, RK, REM, SELF), default) => ct(outDefault, RK, REM, SELF)
  rule setExplicit(ct(EXP, RK, REM, SELF), none) => ct(EXP, RK, REM, SELF)

  rule setRemainder(ct(EXP, estimator, _, SELF), pandas)
    => ct(EXP, estimator, outPandas, SELF)
  rule setRemainder(ct(EXP, estimator, _, SELF), default)
    => ct(EXP, estimator, outDefault, SELF)
  rule setRemainder(ct(EXP, estimator, REM, SELF), none)
    => ct(EXP, estimator, REM, SELF)
  rule setRemainder(ct(EXP, sentinel, REM, SELF), _)
    => ct(EXP, sentinel, REM, SELF)

  // scikit-learn clone copies _sklearn_output_config; the abstract observable
  // is that the fit-time remainder clone has the same output kind.
  rule cloneRemainderOutput(ct(_, estimator, REM, _)) => REM
  rule cloneRemainderOutput(ct(_, sentinel, REM, _)) => REM

  // Dense _hstack takes the pandas branch only when the ColumnTransformer
  // config is pandas and every child output is pandas-like.
  rule hstackBranch(outPandas, outPandas, outPandas) => usePandas
  rule hstackBranch(_, _, _) => useArray [owise]
endmodule
