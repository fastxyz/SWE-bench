requires "mini-axios-timeout.k"

module MINI-AXIOS-TIMEOUT-SPEC
  imports MINI-AXIOS-TIMEOUT

  // SPEC-PROVENANCE:
  // - from_prompt: "expected custom error message, got 'timeout of *ms exceeded'"
  //   => Node timeout rejection must use the configured custom message.
  // - from_code: V1 implements config.timeoutErrorMessage || default timeout text.
  claim
    <k> handleTimeout => .K </k>
    <timeout> T:Int </timeout>
    <custom> someCustom(M:String) </custom>
    <clarify> CL:Bool </clarify>
    <aborted> false => true </aborted>
    <rejected> none => rejected(customMsg(M), chooseCode(CL)) </rejected>
    requires T >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_existing_behavior: existing default timeout text remains required when
  //   timeoutErrorMessage is absent or falsy.
  // - from_xhr_adapter: browser timeout handler falls back to the generated
  //   timeout text when config.timeoutErrorMessage is not truthy.
  claim
    <k> handleTimeout => .K </k>
    <timeout> T:Int </timeout>
    <custom> noCustom </custom>
    <clarify> CL:Bool </clarify>
    <aborted> false => true </aborted>
    <rejected> none => rejected(defaultMsg(T), chooseCode(CL)) </rejected>
    requires T >Int 0
    [all-path]
endmodule
