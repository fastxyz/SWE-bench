# Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | `benchmark/PROBLEM.md` | "`call_command('my_command', shop_id=1)`" fails even though `shop_id` is in a required mutually exclusive group | include supplied required-group kwargs in synthetic parse args | encoded in PO-003 and `call-command-spec.k` |
| E-002 | `benchmark/PROBLEM.md` | "`--shop-id=1`" works | synthetic kwarg path should make argparse observe equivalent option presence | encoded in PO-003 |
| E-003 | source comment | required `**options` must be passed to `parse_args()` | preserve required plain option behavior | encoded in PO-002 |
| E-004 | source implementation | `defaults = dict(defaults._get_kwargs(), **arg_options)` | final command options still come from kwargs after parser validation | encoded in PO-005 |
| E-005 | source implementation | unknown option check uses original option keys and parser action dests | preserve `TypeError` for truly unknown kwargs | encoded in PO-006 |
