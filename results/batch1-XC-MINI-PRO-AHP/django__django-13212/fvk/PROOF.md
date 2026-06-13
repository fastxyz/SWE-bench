# PROOF.md — constructed proof for the validators `value`-in-params fix

**Status: CONSTRUCTED, NOT MACHINE-CHECKED.** No K toolchain (`kompile`/`kprove`)
exists in this environment; the proof is built by symbolic execution against
[`validators-mini.k`](validators-mini.k) and the run-commands to confirm it are in §5.

The target is straight-line guard→raise code: **no loops, no recursion ⇒ no
loop-invariant circularities.** The proof is a short symbolic execution plus a
case-analysis over reject sites; the only nontrivial discharge is the rendering
side condition (PO3), and the only named gap is the `str.__mod__` [ESCALATION
BOUNDARY] (§6).

---

## 1. What is proved (plain language)

For **every** built-in validator in `django.core.validators`:

1. if it rejects a value `x`, the raised `ValidationError` carries
   `params['value'] == x` — the value **as provided** (PO1, PO5);
2. if it accepts `x`, it returns `None` and raises nothing (PO2);
3. every built-in **default** message renders to exactly the same text as before the
   fix (PO3);
4. no per-call params state leaks onto the instance, so migrations/`__eq__` are
   unaffected (PO4).

## 2. Proof of (CONTRACT-REJECT) — PO1 + PO5

Goal: `reject(V, M, C, ("value"|->V) P0) ∧ invalid(V) ⇒ <exc> = verr(M,C,("value"|->V) P0)`.

Symbolic execution (one Axiom step):
- The configuration `<k> reject(V,M,C,("value"|->V) P0) ...</k> <exc> noExc </exc>`
  has `invalid(V)` in its constraint (precondition).
- The reject rule’s `requires invalid(V)` is therefore entailed (Consequence, Z3:
  `invalid(V) → invalid(V)`), so the rule fires:
  `<k> .K ...</k> <exc> verr(M, C, ("value"|->V) P0) </exc>`.
- The `<exc>` cell now matches the postcondition **with the same `V`** introduced by
  the precondition. Value-identity (PO5) is immediate: the variable in
  `params["value"]` is literally the variable from `reject(V, …)`.

This claim is the *fragment-level* contract. The **formalization step** that ties it
to the patched source is: each concrete `raise ValidationError(msg, code=code,
params={'value': value, …})` site maps to `reject(value, msg, code, {"value"|->value, …})`.
By inspection of `validators.py` after V2, **all 21 reject sites** have this shape:

- `RegexValidator.__call__` L51; `URLValidator` L103/107/118/140/147 (direct) and the
  IDN retry (L124–129, see §3); `EmailValidator` L216/221/233; `validate_ipv4_address`
  L280; `validate_ipv6_address` L285; `validate_ipv46_address` L295;
  `BaseValidator.__call__` L346–348 (`params` includes `'value': value`);
  `DecimalValidator` L446/468/474/481; `FileExtensionValidator` L512–519;
  `ProhibitNullCharactersValidator` L559.

V1 counterexamples (PO1): `DecimalValidator` sites mapped to `reject(value, msg,
code, {"max"|->…})` — **no `"value"` key** → CONTRACT-REJECT unprovable (the post-map
cannot be written with `"value"|->V`). Likewise `FileExtensionValidator`. V2 adds the
key, restoring provability. (Findings F1, F2.)

## 3. The `URLValidator` IDN sub-path — PO5 case analysis

`URLValidator.__call__` has several reject sites; PO5 requires every one to report
the *provided* `value`. Case-split on which site fires:

- **Non-string / bad-scheme / `urlsplit` ValueError / IPv6 / >253** (L103,107,118,140,147):
  each constructs `params={'value': value}` directly with the method’s own `value`. ✔
- **Trivial regex failure, no IDN** (`super().__call__(value)` at L111 raises): the
  exception `e` has `params={'value': value}` (RegexValidator on the *original*
  `value`); on the `else: raise` (L131) or `except UnicodeError: raise e` (L122) it
  propagates `e`. ✔
- **IDN retry** (L123–129): `url = urlunsplit((scheme, punycode(netloc), …))` is the
  ACE-normalized URL.
  - **V1:** `super().__call__(url)` raises `verr(msg, 'invalid', {'value': url})` —
    `url` ≠ provided value for true IDN inputs ⇒ **PO5 fails** (Finding F3).
  - **V2:** the call is wrapped:
    ```python
    try:
        super().__call__(url)
    except ValidationError:
        raise e          # original failure: params={'value': value}
    ```
    On failure we re-raise `e`, whose `params['value']` is the provided `value`. ✔
    On success, no exception — control falls through to the L146 length check,
    identical to V1 (PO2 preserved; the IDN-success path is untouched).

So after V2 every `URLValidator` reject site satisfies `params['value'] is value`.

## 4. Proof of (RENDER-DEFAULT) — PO3, and the enumeration

Goal: `render(M, ("value"|->_) P) ⇒ M` given `noPercent(M)`.

One Axiom step: the render rule fires under `requires noPercent(M)` (entailed by the
precondition), rewriting `render(M, _) ⇒ M` and `<out> ⇒ M`. Discharged.

The side condition `noPercent(m)` is checked by **enumerating every built-in default
message** and confirming none contains `%`:

```
RegexValidator        "Enter a valid value."
URLValidator          "Enter a valid URL."
integer_validator     "Enter a valid integer."
EmailValidator        "Enter a valid email address."
validate_slug         "Enter a valid “slug” consisting of letters, numbers, underscores or hyphens."
validate_unicode_slug "Enter a valid “slug” consisting of Unicode letters, numbers, underscores, or hyphens."
validate_…_integer_list "Enter only digits separated by commas."
validate_ipv4_address "Enter a valid IPv4 address."
validate_ipv6_address "Enter a valid IPv6 address."
validate_ipv46_address "Enter a valid IPv4 or IPv6 address."
ProhibitNullCharacters "Null characters are not allowed."
auth ASCII/Unicode username "Enter a valid username. … @/./+/-/_ characters."
```

None contains a `%`. (The validators that *do* use `%(...)s` in their default
message — `BaseValidator` family, `DecimalValidator`, `FileExtensionValidator` —
already passed `params` before this fix, so their rendering path is unchanged by it;
their placeholders reference `limit_value`/`show_value`/`max`/`extension`/
`allowed_extensions`, and the added `value` key is simply unused by those templates.)

⇒ For every default message, adding `params={'value': …}` changes the rendered text
by **nothing**. PO3 holds. No existing test that asserts a default message string can
break.

## 5. Reproduce the machine check

```sh
kompile validators-mini.k --backend haskell      # compile the fragment semantics
kast    --backend haskell validators-spec.k      # (optional) confirm claims parse
kprove  validators-spec.k                         # discharge the 3 claims; expect #Top
```

Expected: `#Top` for (CONTRACT-REJECT), (CONTRACT-ACCEPT), (RENDER-DEFAULT). Until
that is run, every result here is **constructed, not machine-checked**.

## 6. Residual risk

- **Partial vs total:** trivially total — no loops; each `__call__` is straight-line
  and terminates. (The abstract oracle `invalid(·)` stands in for the regex/parse,
  whose termination is Django’s, not ours.)
- **Trusted base:** (a) the mini-Python fragment faithfully models `if`-guarded raise,
  per-call `dict` construction, and `ValidationError` capture; (b) only the
  `noPercent ⇒ identity` slice of `str.__mod__` is modelled — the rest is an
  **[ESCALATION BOUNDARY]**, not `[trusted]`; (c) reachability metatheory + `kprove`,
  not yet executed.
- **F4 (accepted behaviour change):** because params is now always truthy,
  `ValidationError.__iter__` runs `message %= params` for the patched validators even
  when the message has a bare, unescaped `%`. For *default* messages this is the
  identity (§4); for a *custom* message like `'100% off'` it now raises `ValueError`
  where pre-fix it did not. This matches the pre-existing `BaseValidator` behaviour
  and Django’s “escape `%` as `%%`” convention; it cannot be mitigated at the
  validator layer without changing `ValidationError.__iter__` (out of scope). Reported,
  not fixed.

## 7. Test-redundancy report (benefit 1) — RECOMMENDATION ONLY, conditioned on machine-check

The existing `tests/validators/tests.py` suite is dominated by `TEST_DATA`
`(validator, value, expected)` rows that assert **which inputs raise vs. pass** —
i.e. they exercise the `invalid(·)` oracle (regex/parse/range correctness). **Our
spec deliberately abstracts `invalid(·)`; the proof says nothing about it.** Therefore:

- **KEEP all `TEST_DATA` rows** — out of the verified contract’s domain (they pin
  `invalid(·)`, not the params/`value` behaviour). Not redundant.
- **KEEP** `test_max_length_validator_message` and any new `%(value)s` rendering
  tests — they pin the *integration* between a validator’s `params` and
  `ValidationError.__iter__`’s `%`-formatting, which our fragment models only as the
  abstract `render`. Integration tests are always kept.
- **No test is recommended for removal.** Even where (CONTRACT-REJECT) would, once
  machine-checked, subsume a single-point assertion like “`params['value'] == 'blah'`,”
  the honesty gate forbids acting on it before `kprove` returns `#Top`, and these
  tests are cheap and guard the trusted base (the `str.__mod__` boundary). CI savings:
  ~0 — this fix’s value is *correctness/consistency*, not test reduction.

---

### Two payoffs (even if you never read the K)

- **Benefit 2 (hidden bugs):** writing the uniform contract surfaced **F1/F2**
  (two validators silently can’t use `%(value)s`) and **F3** (URL IDN reports the
  punycode form, not the user’s input) — concrete `input → observed vs expected`
  gaps, each now fixed; plus **F4**, a subtle rendering behaviour change, surfaced
  and consciously accepted.
- **Benefit 1 (fewer tests):** analysed; here it correctly yields *keep everything* —
  the suite tests the orthogonal `invalid(·)` predicate, so the proof subsumes none
  of it. Honest zero beats a false saving.
