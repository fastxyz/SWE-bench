# FVK Notes

Status: constructed, not machine-checked. I did not run tests, Python, or K
tooling.

## Decisions and Traceability

1. Kept V1's core design: fix subparser construction rather than wrapping
   parsing in `run_from_argv()`.

   Trace: `fvk/FINDINGS.md` F1 identifies the missing child parser error mode
   as the bug. `fvk/PROOF_OBLIGATIONS.md` PO1, PO3, and PO7 show that copying
   `called_from_command_line` into Django child parser construction is enough to
   move CLI child parser errors onto argparse's usage/error path while keeping
   the repair local.

2. Preserved programmatic `call_command()` behavior.

   Trace: `fvk/FINDINGS.md` F2 records that programmatic parsing must still
   raise `CommandError`. `fvk/PROOF_OBLIGATIONS.md` PO2 and PO3 require a false
   parent mode to produce false child mode and therefore the existing
   `CommandError` branch.

3. Refined V1 so non-Django `parser_class` values are not rewritten.

   Trace: `fvk/FINDINGS.md` F3 found that V1 over-touched `parser_class` by
   popping and reassigning it unconditionally. `fvk/PROOF_OBLIGATIONS.md` PO4
   requires non-Django parser classes or factories to remain controlled by
   argparse. The V2 code now only assigns `kwargs["parser_class"]` when the
   selected parser class is a `CommandParser` class or subclass.

4. Refined V1 so the inherited mode is a snapshot, not a late-bound parent
   attribute lookup.

   Trace: `fvk/FINDINGS.md` F4 records the robustness issue. PO1 and PO5 require
   a copied default mode for constructed child parsers and explicit child kwargs
   to retain precedence. The V2 wrapper captures `called_from_command_line` in a
   local variable and uses `setdefault()`.

5. Kept V1's decision not to propagate `missing_args_message`.

   Trace: `fvk/FINDINGS.md` F5 explains that a command-level missing-argument
   message can be wrong after a subcommand has already been selected.
   `fvk/PROOF_OBLIGATIONS.md` PO6 makes this a frame condition: the wrapper
   defaults only `called_from_command_line`, leaving child
   `missing_args_message` unset unless explicitly provided.

6. Did not modify tests or claim machine verification.

   Trace: `fvk/FINDINGS.md` F6 and `fvk/PROOF_OBLIGATIONS.md` PO8 record the
   environment constraint and the exact commands that would be used for a later
   machine check. The proof remains constructed, not machine-checked, and no
   test-removal recommendation is applied.

## Changed Files

`repo/django/core/management/base.py`

V2 keeps the V1 `CommandParser.add_subparsers()` hook but narrows it:

- reads `parser_class` for classification without removing it from `kwargs`;
- snapshots `called_from_command_line`;
- wraps only `CommandParser` classes and subclasses;
- uses `setdefault()` so explicit child kwargs win.

`fvk/SPEC.md`

Defines the public intent, evidence ledger, abstract parser-construction model,
claims, and adequacy audit.

`fvk/FINDINGS.md`

Records the V1-confirming finding, the two V2 refinements, the rejected
`missing_args_message` alternative, and the no-execution caveat.

`fvk/PROOF_OBLIGATIONS.md`

States the abstract K-style claims, proof obligations, and non-executed
verification commands.

`fvk/PROOF.md`

Constructs the proof over the obligations and traces each finding to the
obligations that discharge it.

`fvk/ITERATION_GUIDANCE.md`

Summarizes why V2 should stand and what tests/formalization would be useful in
a normal development iteration.
