requires "mini-django-usercreationform.k"

module USERCREATIONFORM-SAVE-SPEC
  imports MINI-DJANGO-UCF
  imports LIST

  // SPEC-PROVENANCE:
  // - from_prompt: "UserCreationForm should save data from ManyToMany form fields"
  //   => committed save persists related form data.
  // - from_docs: "When you use a save() on a form, all data -- including
  //   many-to-many data -- is saved" => no caller-side save_m2m is required
  //   when commit=True.
  // - from_docs: many-to-many data cannot be saved until the instance exists
  //   in the database => userSave must precede saveM2M.
  // - from_code: V1 sequence is super().save(commit=False), set_password,
  //   user.save(), save_m2m(), return user.
  // Claim name in the markdown artifacts: C-COMMIT-TRUE-M2M.
  claim [commitTrueM2M]:
    <k> super_save_false ; set_password ; if_commit_save => .K </k>
    <commit> true </commit>
    <valid> true </valid>
    <hasM2M> true </hasM2M>
    <m2m> noM2M => savedM2M </m2m>
    <password> rawPassword => hashedPassword </password>
    <userSaved> false => true </userSaved>
    <result> noReturn => user </result>
    <events>
      .List
      => ListItem(superSaveFalse)
         ListItem(setPassword)
         ListItem(userSave)
         ListItem(saveM2M)
         ListItem(returnUser)
    </events>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: save(commit=False) adds save_m2m() for later caller use
  //   because the instance is not yet saved.
  // - from_prompt: the issue concerns commit=True, so commit=False behavior is
  //   a frame condition to preserve.
  // - from_code: V1 only calls save_m2m() inside the commit branch.
  // Claim name in the markdown artifacts: C-COMMIT-FALSE-M2M.
  claim [commitFalseM2M]:
    <k> super_save_false ; set_password ; if_commit_save => .K </k>
    <commit> false </commit>
    <valid> true </valid>
    <hasM2M> true </hasM2M>
    <m2m> noM2M => pendingM2M </m2m>
    <password> rawPassword => hashedPassword </password>
    <userSaved> false </userSaved>
    <result> noReturn => user </result>
    <events>
      .List
      => ListItem(superSaveFalse)
         ListItem(setPassword)
         ListItem(returnUser)
    </events>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: UserCreationForm is a ModelForm for creating users and sets
  //   passwords with set_password().
  // - from_code: calling save_m2m() with no m2m fields leaves the m2m state
  //   empty while preserving user save and password behavior.
  // Claim name in the markdown artifacts: C-COMMIT-TRUE-NO-M2M.
  claim [commitTrueNoM2M]:
    <k> super_save_false ; set_password ; if_commit_save => .K </k>
    <commit> true </commit>
    <valid> true </valid>
    <hasM2M> false </hasM2M>
    <m2m> noM2M </m2m>
    <password> rawPassword => hashedPassword </password>
    <userSaved> false => true </userSaved>
    <result> noReturn => user </result>
    <events>
      .List
      => ListItem(superSaveFalse)
         ListItem(setPassword)
         ListItem(userSave)
         ListItem(saveM2M)
         ListItem(returnUser)
    </events>
    [all-path]
endmodule
