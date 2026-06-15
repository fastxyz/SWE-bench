# Formal Spec In English

FSE-001. If a required mutually exclusive group contains `shop_id` and
`shop_name`, and the caller supplies `shop_id` in kwargs, synthetic parser
tokens include the corresponding option before `parse_args()`.

FSE-002. If an ordinary required option is supplied in kwargs, synthetic parser
tokens still include that option before `parse_args()`.

FSE-003. If no kwarg from a required mutually exclusive group is supplied,
`call_command()` does not fabricate a group token. Argparse remains responsible
for raising the required-group error.

FSE-004. If more than one kwarg from the same mutually exclusive group is
supplied, V1 passes all supplied group options through synthetic parsing, so
argparse remains responsible for rejecting the conflict.

FSE-005. The public callable shape and final `command.execute()` option overlay
remain unchanged.
