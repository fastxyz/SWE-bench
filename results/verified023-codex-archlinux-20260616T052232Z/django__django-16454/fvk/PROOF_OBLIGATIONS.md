# FVK Proof Obligations

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Abstract Semantics

The proof uses a mini parser-construction semantics with these operations:

```text
addSubparsers(parentParser, kwargs) -> subparserAction
addParser(subparserAction, childKwargs) -> childParser
error(parser, message) -> ErrCLI(message) | ErrProgrammatic(message)
```

The modeled implementation is the V2 source in
`repo/django/core/management/base.py`:

```text
parser_class = kwargs.get("parser_class", type(parent))
if parser_class is CommandParser or a subclass:
    command_parser_class = parser_class
    called_from_command_line = parent.called_from_command_line
    kwargs["parser_class"] = wrapper(default called_from_command_line)
return argparse_add_subparsers(parent, kwargs)
```

The wrapper semantics:

```text
wrapper(child_kwargs):
    child_kwargs.setdefault("called_from_command_line", inherited_mode)
    return command_parser_class(**child_kwargs)
```

`CommandParser.error()` semantics:

```text
error(CP(True), message)  => ErrCLI(message)
error(CP(False), message) => ErrProgrammatic(message)
error(CP(None), message)  => ErrProgrammatic(message)
```

## K-Style Claims

These are K-style reachability claims over the abstract semantics. They are
included here as constructed proof artifacts, not as executed verifier output.

```k
// PO1 / SPEC-PROVENANCE:
// - from_problem: "subparsers don't retain error formatting"
// - from_code: BaseCommand.run_from_argv() sets called_from_command_line = True
claim
  <k>
    addParser(addSubparsers(CP(true, MISSING), .Kwargs), .ChildKwargs)
    => Child(true, .NoMissing)
  </k>
  [all-path]
```

```k
// PO2 / SPEC-PROVENANCE:
// - from_code: BaseCommand._called_from_command_line defaults to False
// - from_code: call_command() parses programmatically
claim
  <k>
    addParser(addSubparsers(CP(false, MISSING), .Kwargs), .ChildKwargs)
    => Child(false, .NoMissing)
  </k>
  [all-path]
```

```k
// PO3 / SPEC-PROVENANCE:
// - from_code: CommandParser.error() delegates on true mode and raises on false
claim
  <k> error(Child(true, MISSING), MSG) => ErrCLI(MSG) </k>
  [all-path]

claim
  <k> error(Child(false, MISSING), MSG) => ErrProgrammatic(MSG) </k>
  [all-path]
```

```k
// PO4 / SPEC-PROVENANCE:
// - from_compatibility: non-Django parser_class is caller-controlled argparse API
claim
  <k>
    addSubparsers(CP(MODE, MISSING), parserClass(AP))
    => Action(AP)
  </k>
  requires notBool isCommandParserClass(AP)
  [all-path]
```

```k
// PO5 / SPEC-PROVENANCE:
// - from_code: wrapper uses setdefault(), so explicit child kwarg wins
claim
  <k>
    addParser(
      addSubparsers(CP(PARENTMODE, MISSING), .Kwargs),
      childKwarg("called_from_command_line", EXPLICITMODE)
    )
    => Child(EXPLICITMODE, .NoMissing)
  </k>
  [all-path]
```

```k
// PO6 / SPEC-PROVENANCE:
// - from_intent: command-level missing_args_message is not necessarily a child
//   subparser message
claim
  <k>
    addParser(addSubparsers(CP(MODE, parentMissingMessage), .Kwargs), .ChildKwargs)
    => Child(MODE, .NoMissing)
  </k>
  [all-path]
```

```k
// PO7 / SPEC-PROVENANCE:
// - from_problem: fix belongs in subparser construction
// - from_code: run_from_argv() parse/execute structure is unchanged
claim
  <k>
    runFromArgvParseWithSubparserError(CP(true, MISSING), MSG)
    => ErrCLI(MSG)
  </k>
  [all-path]
```

## Obligations

PO1. CLI mode propagation:
Given a parent `CommandParser` with `called_from_command_line = True` and no
caller-supplied non-Django `parser_class`, `add_subparsers().add_parser()`
constructs a Django child parser whose `called_from_command_line` defaults to
`True`.

PO2. Programmatic mode propagation:
Given a parent `CommandParser` with `called_from_command_line = False` and no
caller-supplied non-Django `parser_class`, `add_subparsers().add_parser()`
constructs a Django child parser whose `called_from_command_line` defaults to
`False`.

PO3. Error behavior:
For child parsers from PO1, `error(message)` reaches argparse's CLI usage/error
path. For child parsers from PO2, `error(message)` reaches Django's
`CommandError` path.

PO4. Non-Django parser-class frame condition:
If `parser_class` is supplied and is not a `CommandParser` class or subclass,
`add_subparsers()` must not replace it or inject Django-only kwargs.

PO5. Explicit child kwarg precedence:
If `add_parser()` explicitly supplies `called_from_command_line`, that value
overrides the inherited default.

PO6. Missing-args-message frame condition:
The parent parser's `missing_args_message` is not inherited by default. A child
parser may have one only through explicit child parser kwargs.

PO7. Locality of the fix:
No obligation relies on changing `run_from_argv()`, `call_command()`,
`CommandParser.error()`, or test files. The repair is localized to child parser
construction.

PO8. Machine-check commands, not executed:

```sh
kompile fvk/mini-command-parser.k --backend haskell
kast --backend haskell fvk/command-parser-spec.k
kprove fvk/command-parser-spec.k
```

Expected if the abstract K files were materialized from these claims and the
toolchain were run: `#Top`. In this task, these commands are recorded only.
