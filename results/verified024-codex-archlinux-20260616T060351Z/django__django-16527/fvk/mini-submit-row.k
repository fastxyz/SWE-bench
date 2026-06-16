module MINI-SUBMIT-ROW
  imports BOOL

  configuration <k> $PGM:K </k>

  syntax Bool ::= showSaveAsNew(Bool, Bool, Bool, Bool, Bool) [function]

  rule showSaveAsNew(IS_POPUP, HAS_ADD_PERMISSION, HAS_CHANGE_PERMISSION, CHANGE, SAVE_AS)
    => notBool(IS_POPUP)
       andBool HAS_ADD_PERMISSION
       andBool HAS_CHANGE_PERMISSION
       andBool CHANGE
       andBool SAVE_AS
endmodule
