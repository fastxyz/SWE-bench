requires "mini-python.k"

module HUBER-FIT-SPEC
  imports MINI-PYTHON-HUBER

  // SPEC-PROVENANCE:
  // - from_prompt: "No error is thrown when dtype of X is bool" =>
  //   boolean predictors are in-domain for HuberRegressor.fit.
  // - from_prompt: "Boolean array is expected to be converted to float" =>
  //   validation must convert bool before the optimizer/gradient path.
  // - from_code: V1 passes dtype=FLOAT_DTYPES to check_X_y.
  claim
    <k> fitV1(matrix(S:Storage, bool, R:Int, C:Int)) => .K ... </k>
    <validatedDType> unknownDType => float64 </validatedDType>
    <error> noError => noError </error>
    requires R >=Int 1 andBool C >=Int 1
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: fit(X, y) and fit(X_bool_as_float, y) already work =>
  //   already-floating input is a frame condition.
  // - from_code: check_array with dtype list leaves dtypes in the list
  //   unchanged.
  claim
    <k> fitV1(matrix(S:Storage, DT:DType, R:Int, C:Int)) => .K ... </k>
    <validatedDType> unknownDType => DT </validatedDType>
    <error> noError => noError </error>
    requires R >=Int 1 andBool C >=Int 1 andBool isFloatDType(DT)
    [all-path]

  // Diagnostic counterfactual, not a desired postcondition.
  // SPEC-PROVENANCE:
  // - from_issue_trace: the pre-fix fit path lets bool X reach
  //   _huber_loss_and_gradient, where unary minus on axis0_safe_slice(X,...)
  //   raises TypeError.
  claim
    <k> fitV0(matrix(S:Storage, bool, R:Int, C:Int)) => .K ... </k>
    <validatedDType> unknownDType => bool </validatedDType>
    <error> noError => boolNegativeTypeError </error>
    requires R >=Int 1 andBool C >=Int 1
    [all-path]
endmodule
