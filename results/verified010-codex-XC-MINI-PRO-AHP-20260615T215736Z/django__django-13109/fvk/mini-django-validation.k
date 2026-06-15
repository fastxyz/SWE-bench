module MINI-DJANGO-VALIDATION-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX

  syntax Manager ::= BaseManager | DefaultManager
  syntax Outcome ::= Valid | Invalid
  syntax KResult ::= Outcome
  syntax KItem ::= ValidateFK "(" Manager "," Int "," Bool "," Bool "," Bool ")"
endmodule

module MINI-DJANGO-VALIDATION
  imports MINI-DJANGO-VALIDATION-SYNTAX
  imports BOOL
  imports INT

  configuration <k> $PGM:K </k>

  // ValidateFK(manager, value, baseExists, defaultExists, limitAllows)
  // Abstracts the Django query:
  //   manager.filter(remote_field=value).complex_filter(limit_choices_to).exists()
  rule <k> ValidateFK(BaseManager, _VALUE:Int, true, _DEFAULT_EXISTS:Bool, true) => Valid ... </k>
  rule <k> ValidateFK(BaseManager, _VALUE:Int, false, _DEFAULT_EXISTS:Bool, _LIMIT_OK:Bool) => Invalid ... </k>
  rule <k> ValidateFK(BaseManager, _VALUE:Int, true, _DEFAULT_EXISTS:Bool, false) => Invalid ... </k>

  rule <k> ValidateFK(DefaultManager, _VALUE:Int, _BASE_EXISTS:Bool, true, true) => Valid ... </k>
  rule <k> ValidateFK(DefaultManager, _VALUE:Int, _BASE_EXISTS:Bool, false, _LIMIT_OK:Bool) => Invalid ... </k>
  rule <k> ValidateFK(DefaultManager, _VALUE:Int, _BASE_EXISTS:Bool, true, false) => Invalid ... </k>
endmodule
