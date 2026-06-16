module MINI-DJANGO-UCF-SYNTAX
  imports BOOL-SYNTAX

  syntax UserRef ::= "user"
  syntax Return ::= "noReturn" | UserRef
  syntax PasswordState ::= "rawPassword" | "hashedPassword"
  syntax M2MState ::= "noM2M" | "pendingM2M" | "savedM2M"
  syntax Event ::= "superSaveFalse" | "setPassword" | "userSave" | "saveM2M" | "returnUser"

  syntax Stmt ::= "super_save_false"
                | "set_password"
                | "if_commit_save"
                | "user_save"
                | "save_m2m"
                | "return_user"
                | Stmt ";" Stmt [left]

  syntax KResult ::= UserRef
endmodule

module MINI-DJANGO-UCF
  imports MINI-DJANGO-UCF-SYNTAX
  imports BOOL
  imports LIST

  configuration
    <k> $PGM:Stmt </k>
    <commit> false </commit>
    <valid> true </valid>
    <hasM2M> false </hasM2M>
    <m2m> noM2M </m2m>
    <password> rawPassword </password>
    <userSaved> false </userSaved>
    <result> noReturn </result>
    <events> .List </events>

  rule <k> S1:Stmt ; S2:Stmt => S1 ~> S2 ... </k>

  // super().save(commit=False): on the verified valid-form path, ModelForm
  // prepares an instance and installs the deferred save_m2m hook.
  rule <k> super_save_false => .K ... </k>
       <valid> true </valid>
       <hasM2M> true </hasM2M>
       <m2m> noM2M => pendingM2M </m2m>
       <events> ES:List => ES ListItem(superSaveFalse) </events>

  rule <k> super_save_false => .K ... </k>
       <valid> true </valid>
       <hasM2M> false </hasM2M>
       <m2m> noM2M </m2m>
       <events> ES:List => ES ListItem(superSaveFalse) </events>

  rule <k> set_password => .K ... </k>
       <password> rawPassword => hashedPassword </password>
       <events> ES:List => ES ListItem(setPassword) </events>

  rule <k> if_commit_save => user_save ; save_m2m ; return_user ... </k>
       <commit> true </commit>

  rule <k> if_commit_save => return_user ... </k>
       <commit> false </commit>

  rule <k> user_save => .K ... </k>
       <userSaved> false => true </userSaved>
       <events> ES:List => ES ListItem(userSave) </events>

  rule <k> save_m2m => .K ... </k>
       <userSaved> true </userSaved>
       <m2m> pendingM2M => savedM2M </m2m>
       <events> ES:List => ES ListItem(saveM2M) </events>

  rule <k> save_m2m => .K ... </k>
       <userSaved> true </userSaved>
       <m2m> noM2M </m2m>
       <events> ES:List => ES ListItem(saveM2M) </events>

  rule <k> return_user => .K ... </k>
       <result> noReturn => user </result>
       <events> ES:List => ES ListItem(returnUser) </events>
endmodule
