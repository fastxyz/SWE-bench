# Public Evidence Ledger

## L1: Reported failure for one missing mask

- Source: prompt issue description.
- Evidence: "when one of the operand does not have a mask, the mask propagation
  when doing arithmetic, in particular with `handle_mask=np.bitwise_or` fails."
- Obligation: callable mask propagation must not fail solely because one mask is
  absent.
- Status: encoded by PO-2, PO-3, and PO-6.

## L2: Expected copy of the sole present mask

- Source: prompt expected behavior.
- Evidence: "When one of the operand does not have mask, the mask that exists
  should just be copied over to the output."
- Obligation: exactly one present mask produces `Copy(present_mask)`.
- Status: encoded by PO-2 and PO-3.

## L3: Both absent means no mask

- Source: prompt reproduction marked OK.
- Evidence: "`no mask * no mask` returns nothing, no mask, OK."
- Obligation: no present masks produce result mask `None`.
- Status: encoded by PO-1.

## L4: Both present delegates to the callable

- Source: prompt reproduction marked OK.
- Evidence: "`mask * mask` with `np.bitwise_or` returns the original integer
  bitmask array."
- Obligation: when both masks are present and `handle_mask` is callable, the
  callable receives both present masks.
- Status: encoded by PO-4.

## L5: Boolean masks should not gain `None` entries

- Source: public issue discussion.
- Evidence: "Those `None`s should probably be `False`s not None's" and "the
  `mask` isn't a nice happy numpy `bool` array anymore."
- Obligation: callable propagation must avoid constructing object masks by
  combining a real mask with `None`.
- Status: encoded by PO-3 and F-002.

## L6: Integer bitmasks are in domain

- Source: public issue discussion.
- Evidence: "The nature of the 'badness' of each pixel matters... That why we
  need bits."
- Obligation: the sole present mask must be preserved without coercing integer
  bitmask values to boolean.
- Status: encoded by PO-2, PO-3, and PO-7.

## L7: Local implementation contract

- Source: `repo/astropy/nddata/mixins/ndarithmetic.py` return documentation.
- Evidence: "`If only one mask was present this mask is returned. If neither had
  a mask `None` is returned. Otherwise `handle_mask` must create ... the
  returned mask.`"
- Obligation: `_arithmetic_mask` must short-circuit zero-mask and one-mask cases
  before invoking `handle_mask`.
- Status: encoded by PO-1 through PO-4.

## L8: `handle_mask=None` disables mask propagation

- Source: arithmetic method docstring.
- Evidence: "If `None` the result will have no mask."
- Obligation: `handle_mask is None` returns no mask regardless of operand masks.
- Status: encoded by PO-5.
