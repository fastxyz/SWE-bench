requires "mini-call-command.k"

module CALL-COMMAND-SPEC
  imports MINI-CALL-COMMAND

  // SPEC-PROVENANCE:
  // - from_prompt: "call_command fails when argument of required mutually
  //   exclusive group is passed in kwargs" => a supplied group kwarg must be
  //   represented in the synthetic parse token list.
  // - from_prompt: "everything is fine when I call this command ...
  //   '--shop-id=1'" => the synthetic form must make argparse observe the same
  //   option presence as the command-line spelling.
  // - from_code: V1 extends the required-option synthesis with actions from
  //   parser._mutually_exclusive_groups where group.required is true.
  claim <k> callCommand(
              action("shop_id", "--shop-id", false, 1)
              action("shop_name", "--shop", false, 1)
              .Actions,
              requiredGroup(SetItem("shop_id") SetItem("shop_name")) .Groups,
              SetItem("shop_id"),
              .List
            )
        => parsed(ListItem(token("--shop-id=VALUE"))) ... </k>

  // SPEC-PROVENANCE:
  // - from_prompt/source-comment: "Any required arguments which are passed in
  //   via **options must be passed to parse_args()." => ordinary required
  //   action kwargs remain represented in parse tokens.
  // - from_code: V1 keeps the required-action path and only changes the lookup
  //   to normalized arg_options.
  claim <k> callCommand(
              action("need_me", "--need-me", true, 1) .Actions,
              .Groups,
              SetItem("need_me"),
              .List
            )
        => parsed(ListItem(token("--need-me=VALUE"))) ... </k>

  // SPEC-PROVENANCE:
  // - from_prompt: the error is wrong only when a supplied group option should
  //   satisfy the required group; with no supplied group option, argparse's
  //   required-group error remains the intended behavior.
  // - from_code: V1 appends no required-group token when no group dest appears
  //   in arg_options.
  claim <k> callCommand(
              action("shop_id", "--shop-id", false, 1)
              action("shop_name", "--shop", false, 1)
              .Actions,
              requiredGroup(SetItem("shop_id") SetItem("shop_name")) .Groups,
              .Set,
              .List
            )
        => parsed(.List) ... </k>
endmodule
