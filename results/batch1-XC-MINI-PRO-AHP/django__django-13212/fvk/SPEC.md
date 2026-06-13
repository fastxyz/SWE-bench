# SPEC.md — formal specification of the validators `value`-in-params fix

**Target:** `django/core/validators.py` (and the unchanged subclasses that inherit
from it: `django/contrib/auth/validators.py`).
**Issue intent (django__django-13212):** *“Make validators include the provided
value in `ValidationError`”* so that a custom error `message` can interpolate the
rejected value via the `%(value)s` placeholder (the placeholder the docs already
advertise for user-written validators).

This is **not** an arithmetic/loop program, so the K artifacts are small: the code
is straight-line guard→raise. There are **no loops and no recursion**, hence **no
loop-invariant circularities** to discharge. The verification value is *structural*:
every rejection carries the provided value, the accept path is untouched, and
default-message rendering is unchanged. Artifacts:
[`validators-mini.k`](validators-mini.k) (fragment semantics),
[`validators-spec.k`](validators-spec.k) (claims).

---

## 1. The contract (intent-spec mode)

Let `V` be any built-in validator in `django.core.validators` and `x` any input.

A validator is a callable `V(x)` that **returns `None`** when `x` is acceptable and
**raises `ValidationError`** when it is not. The specification of the fix adds one
clause to the rejection behaviour:

> **REJECT contract.** If `V` rejects `x`, the raised `ValidationError e` satisfies
> `e.params is not None`, `'value' in e.params`, and `e.params['value'] is x` —
> where `x` is the value **as provided to `V`**, not an internally derived or
> normalized form.

> **ACCEPT contract.** If `V` accepts `x`, then `V(x)` returns `None` and raises
> nothing. (The fix must not add any rejection.)

> **RENDER invariance.** For every *default* (built-in) message `m`, and any params
> map `p`, `m % p == m`. Consequently the rendered text of every default message is
> identical before and after the fix. (Django renders messages in
> `ValidationError.__iter__` as `message %= error.params` whenever `params` is
> truthy.)

The placeholder mechanism this enables: a user sets
`V = EmailValidator(message='“%(value)s” is not a valid email address.')`; on
rejection of `'blah'`, `e.params['value'] == 'blah'`, and
`'“%(value)s” …' % {'value': 'blah'}` renders `“blah” is not a valid email address.`

## 2. How each validator realizes the contract

| Validator(s) | Reject sites | `value` in params? |
|---|---|---|
| `RegexValidator` (+ `validate_slug`, `validate_unicode_slug`, `integer_validator`/`validate_integer`, `int_list_validator`/`validate_comma_separated_integer_list`, auth `ASCIIUsernameValidator`/`UnicodeUsernameValidator`) | 1 (`__call__`) | yes (V1) |
| `URLValidator` | 5 direct + IDN-retry via `super().__call__` | yes; **IDN-retry site fixed in V2** to report the *provided* value (PO5) |
| `EmailValidator` | 3 | yes (V1); keeps `value` intact, only mutates `domain_part` |
| `validate_ipv4_address`, `validate_ipv6_address`, `validate_ipv46_address` | 1 each | yes (V1) |
| `BaseValidator` (+ `Max/Min Value`, `Max/Min Length`) | 1 | yes — pre-existing (`params={'limit_value','show_value','value'}`) |
| `DecimalValidator` | 4 | **added in V2** (`{'max', …, 'value'}`; `invalid` branch `{'value'}`) |
| `FileExtensionValidator` | 1 | **added in V2** (`{'extension','allowed_extensions','value'}`) |
| `ProhibitNullCharactersValidator` | 1 | yes (V1) |

After V2, **every** rejecting built-in validator binds `params['value']` to the
provided value — a single, uniform contract with no implementation-historical
carve-out.

## 3. Reachability claims (see `validators-spec.k`)

- **(CONTRACT-REJECT)** `reject(V,M,C,("value"|->V) P0) ⇒ ` raises
  `verr(M,C,("value"|->V) P0)` when `invalid(V)`. `P0` is the pre-existing context
  params (`.Map`, or `"max"|->…`, or the file-extension keys). The postcondition
  keeps the *same symbolic* `V` the precondition introduced ⇒ **value identity**.
- **(CONTRACT-ACCEPT)** `reject(V,_,_,_) ⇒ ` leaves `<exc>` = `noExc` when
  `notBool invalid(V)` ⇒ the accept path raises nothing.
- **(RENDER-DEFAULT)** `render(M, ("value"|->_) _) ⇒ M` when `noPercent(M)` ⇒
  default messages are rendering-invariant under the added params.

## 4. Preconditions, side conditions, trusted base

- **Precondition for value-identity (PO5):** the value handed to the raise must be
  the value handed to the validator. True for all sites after V2; the one V1
  counterexample was `URLValidator`’s IDN retry, which validated and reported the
  ACE/punycode-normalized URL — fixed in V2 by re-raising the original error `e`.
- **Side condition for RENDER (PO3):** `noPercent(m)` — holds for every built-in
  default message (enumerated in PROOF.md §4). It does **not** hold for an arbitrary
  *custom* message containing a bare `%`; that is Finding **F3** (a behaviour change
  vs. the pre-fix no-params validators), surfaced but deliberately not “fixed” —
  see FINDINGS.md.
- **Trusted base:** (a) adequacy of the mini-Python fragment vs. real CPython
  control flow and `dict` construction; (b) the modelled slice of `str.__mod__`
  mapping interpolation (`noPercent ⇒ identity`); the rest of `str.__mod__` is an
  **[ESCALATION BOUNDARY]**; (c) the reachability metatheory + `kprove` (the proof
  is **constructed, not machine-checked**).
