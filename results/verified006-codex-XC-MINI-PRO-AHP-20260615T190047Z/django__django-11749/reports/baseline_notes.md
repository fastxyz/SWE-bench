# Baseline Notes

## Root cause

`django.core.management.call_command()` simulates argument parsing by adding
required keyword options to a synthetic `parse_args` list before calling
`parser.parse_args()`. Plain required options are marked on their individual
argparse actions, but actions inside a required mutually exclusive group are not
individually required. As a result, `call_command()` didn't pass a supplied
keyword option from such a group through the parser, so argparse still reported
that one of the group arguments was required.

## Files changed

`repo/django/core/management/__init__.py`

- Added discovery of required mutually exclusive groups, including groups on
  subparsers, and included any supplied group options in the synthetic parser
  arguments.
- Reused the same synthetic parsing path for normal required options and group
  options so argparse continues to perform required and mutual-exclusion
  validation before Django overlays the keyword options onto parsed defaults.
- Normalized the required-option lookup against `arg_options`, matching the
  existing option-name-to-dest mapping used for the final options.

## Assumptions and alternatives considered

- I assumed kwargs that correspond to a required mutually exclusive group should
  be treated as if the equivalent command-line option was present, because the
  parser must see that option to validate the group.
- I kept the change focused on required groups. Optional mutually exclusive
  groups still don't require synthetic parser arguments unless one of their
  actions is otherwise required.
- I considered bypassing argparse's group validation and manually suppressing
  the required-group error when a matching kwarg is present. I rejected that
  because it would duplicate argparse behavior and could miss conflicts when
  multiple mutually exclusive options are supplied.
- I did not modify tests or run the test suite, per the task constraints.
