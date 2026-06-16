// Constructed, not machine-checked.
// Minimal K-style semantics fragment for manager signature introspection.

module MINI-PYTHON-SIGNATURE-SYNTAX
  imports BOOL
  imports STRING
  imports LIST

  syntax Param ::= param(String) | varargs | kwargs
  syntax Params ::= List
  syntax Meta ::= noWrapped | wrapped(Func)
  syntax Func ::= method(String, Params, Meta) | proxy(String, Func)
  syntax Bound ::= bound(String, Func)

  syntax KItem ::= inspectSignature(Bound)
                 | signature(Func)
                 | dropReceiver(Params)
                 | createProxy(String, Func)
endmodule

module MINI-PYTHON-SIGNATURE
  imports MINI-PYTHON-SIGNATURE-SYNTAX

  configuration <k> $PGM:K </k>

  // V1 create_method(): a generic forwarding proxy decorated by wraps(method).
  // The proxy term stores the original method as wrapper metadata.
  rule <k> createProxy(NAME, METHOD) => proxy(NAME, METHOD) ... </k>

  // inspect.signature() follows __wrapped__ metadata on wrapper functions.
  rule <k> signature(proxy(NAME, METHOD)) => signature(METHOD) ... </k>

  // A plain method's signature is its parameter list.
  rule <k> signature(method(NAME, PARAMS, META)) => PARAMS ... </k>

  // Access through a manager instance creates a bound method; displayed
  // signatures omit the receiver parameter.
  rule <k> inspectSignature(bound(RECEIVER, FUNC))
        => dropReceiver(signature(FUNC)) ... </k>

  rule <k> dropReceiver(ListItem(param("self")) REST:List) => REST ... </k>
  rule <k> dropReceiver(PARAMS) => PARAMS ... </k> [owise]
endmodule
