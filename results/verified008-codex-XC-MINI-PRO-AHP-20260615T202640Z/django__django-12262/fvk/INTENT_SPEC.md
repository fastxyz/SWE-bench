# Intent Spec

Status: intent-only, before accepting candidate behavior as expected.

## Required Behaviors

1. Custom template tags may accept keyword-only arguments.
2. A declared keyword-only argument with a default may be supplied explicitly by
   keyword in the template.
3. Supplying the same keyword name twice as template keyword tokens must report
   "received multiple values for keyword argument", not "received unexpected
   keyword argument".
4. The same behavior applies to `simple_tag()` and `inclusion_tag()` because the
   issue identifies shared code.
5. Unknown keyword names remain errors when the tag callable has no `**kwargs`.
6. Required keyword-only arguments without defaults remain required and must be
   reported as missing if omitted.

## Default-Domain Assumptions

- The domain is compile-time parsing of template tag helper arguments that
  `token_kwargs()` recognizes as keyword syntax.
- The proof is partial correctness over `parse_bits()` behavior; it does not
  prove termination or rendering behavior.
- Python-style duplicate keyword wording is required only for repeated keyword
  tokens named by the issue. Broader positional-plus-keyword duplicate behavior
  is left unclaimed.
