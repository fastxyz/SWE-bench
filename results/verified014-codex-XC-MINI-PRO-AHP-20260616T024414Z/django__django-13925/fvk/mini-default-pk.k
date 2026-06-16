module MINI-DEFAULT-PK-SYNTAX
  imports BOOL-SYNTAX

  syntax KItem ::= checkDefaultPk(Bool, Bool, Bool, Bool)
  syntax Bool ::= warnCondition(Bool, Bool, Bool, Bool) [function]
  syntax KResult ::= Bool
endmodule

module MINI-DEFAULT-PK
  imports MINI-DEFAULT-PK-SYNTAX
  imports BOOL

  configuration <k> $PGM:K </k>

  rule warnCondition(
      PK_AUTO_CREATED:Bool,
      PK_IS_AUTO_FIELD:Bool,
      DEFAULT_SETTING_OVERRIDDEN:Bool,
      APP_DEFAULT_AUTO_FIELD_OVERRIDDEN:Bool
    )
    => PK_AUTO_CREATED
       andBool PK_IS_AUTO_FIELD
       andBool notBool DEFAULT_SETTING_OVERRIDDEN
       andBool notBool APP_DEFAULT_AUTO_FIELD_OVERRIDDEN

  rule <k> checkDefaultPk(
      PK_AUTO_CREATED:Bool,
      PK_IS_AUTO_FIELD:Bool,
      DEFAULT_SETTING_OVERRIDDEN:Bool,
      APP_DEFAULT_AUTO_FIELD_OVERRIDDEN:Bool
    )
    => warnCondition(
      PK_AUTO_CREATED,
      PK_IS_AUTO_FIELD,
      DEFAULT_SETTING_OVERRIDDEN,
      APP_DEFAULT_AUTO_FIELD_OVERRIDDEN
    ) ... </k>
endmodule
