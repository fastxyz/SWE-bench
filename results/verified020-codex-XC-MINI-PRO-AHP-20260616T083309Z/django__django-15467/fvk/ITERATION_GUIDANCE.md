# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

Do not revise `repo/django/contrib/admin/options.py` beyond V1.

The audit confirms that V1 satisfies PO1-PO5. The only tempting alternative from
the issue text, `kwargs.get("empty_label") or _("None")`, is rejected by PO6
because it would erase explicit falsy values such as `None`.

## Source Changes

No V2 source edit is justified.

The current code:

```python
kwargs["empty_label"] = (
    kwargs.get("empty_label", _("None")) if db_field.blank else None
)
```

is the minimal change that preserves explicit labels for blank radio foreign
keys while retaining default and nonblank behavior.

## Suggested Tests For A Normal Development Environment

Do not run these in this benchmark session. In a normal Django development
environment, add or keep coverage for:

1. Blank `ForeignKey` in `radio_fields` with custom string `empty_label`.
2. Blank `ForeignKey` in `radio_fields` with `empty_label=None`.
3. Blank `ForeignKey` in `radio_fields` without `empty_label`.
4. Nonblank `ForeignKey` in `radio_fields` with a supplied `empty_label`.

## Residual Risk

The FVK proof is an abstract branch proof, not a full Django runtime proof. It
does not prove admin rendering, translations, query evaluation, or termination.
Those remain integration concerns.

The recorded K commands were intentionally not executed. Keep all tests unless
and until the claims are machine-checked in an environment that supports K.
