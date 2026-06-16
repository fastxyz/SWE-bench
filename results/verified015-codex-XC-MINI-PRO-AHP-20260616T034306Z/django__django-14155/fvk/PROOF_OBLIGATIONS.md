# Proof Obligations

Status: constructed, not machine-checked.

## PO-1 - Unwrap partials for display path

For any `functools.partial` chain wrapping callable `F`, `ResolverMatch.__init__()` must set display path metadata from `F`, not from the partial object's class.

- Evidence: E1, E3.
- Formal claim: `PARTIAL-REPR`, `NESTED-PARTIAL-REPR`.
- Result: discharged by V1 source reasoning.

## PO-2 - Include partial-bound args/kwargs in repr metadata

For any partial chain with bound positional args `PA1..PAn`, bound keyword maps `PK1..PKn`, URL args `A`, and URL kwargs `K`, repr metadata must use `PA1 + ... + PAn + A` and `merge(PK1, ..., PKn, K)`.

- Evidence: E2, E6, default Python partial composition.
- Formal claim: `PARTIAL-REPR`, `NESTED-PARTIAL-REPR`.
- Result: discharged by V1 source reasoning.

## PO-3 - Preserve non-partial repr behavior

For non-partial callbacks, repr must still use the existing function/class path and URL args/kwargs.

- Evidence: public compatibility frame and absence of an issue against non-partials.
- Formal claim: `NONPARTIAL-REPR`.
- Result: discharged because V1's new metadata equals `self.args`/`self.kwargs` when the while loop does not run.

## PO-4 - Preserve public runtime triple

For all callbacks, including partials, `match.func`, `match.args`, `match.kwargs`, and `match[i]` for `i in {0,1,2}` must remain the callback and URL-parsed args/kwargs used by resolve/request dispatch.

- Evidence: E4, E5, E8.
- Formal claim: `FRAME-PUBLIC-TRIPLE`.
- Result: discharged because V1 only writes additional private display metadata after assigning the public attributes.

## PO-5 - Preserve `url_name` precedence in `view_name`

When `url_name` is provided, `view_name` must remain namespace plus `url_name`. When `url_name` is absent, use the same display path that repr uses.

- Evidence: existing source behavior and E1/E3 for partial path display.
- Formal claim: `VIEW-NAME-FRAME`.
- Result: discharged by unchanged `view_path = url_name or self._func_path`.

## PO-6 - Honesty gate and reproducibility commands

The FVK proof must be labeled constructed, not machine-checked, and include exact commands rather than executing them.

- Evidence: FVK `verify.md` and user no-execution constraint.
- Formal artifact: `PROOF.md` command block.
- Result: discharged by artifact contents.

