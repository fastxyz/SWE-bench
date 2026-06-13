# FINDINGS.md — validators `value`-in-params fix (django__django-13212)

Plain-language findings from formalizing the V1 fix, each as
`input → observed vs expected`. Findings that drove a V2 code change are marked
**[FIXED in V2]**; findings deliberately left as-is are marked **[ACCEPTED]** or
**[OUT OF SCOPE]** with the reason.

The spec used is the **uniform** one (SPEC.md §1): *every* rejecting built-in
validator must expose the provided value as `params['value']`. This is the clean
specification; the only alternative is an implementation-historical carve-out
(“only validators that previously had no params”) which the FVK clean-spec lens
flags as itself suspicious. See `reports/fvk_notes.md` for why uniform was chosen
and why extending the fix is provably safe.

---

## F1 — V1 is incomplete: `DecimalValidator` omits `value` **[FIXED in V2]**

- **input:** `DecimalValidator(max_digits=2, decimal_places=1)(Decimal('0.99'))`,
  with a custom message `'%(value)s has too many digits'`.
- **observed (V1):** raises `ValidationError`, but `params == {'max': 2}`. Rendering
  `'%(value)s …' % {'max': 2}` raises **`KeyError: 'value'`** — the placeholder the
  issue is about does not work for this validator.
- **expected (uniform spec):** `params` contains `'value': Decimal('0.99')`, so
  `%(value)s` renders.
- **classification:** missing-postcondition / consistency gap (PO1).
- **fix:** add `'value': value` to all four `DecimalValidator` raises (incl. the
  `invalid`/NaN branch). Rendering-safe: default messages reference only `%(max)s`,
  and Python’s mapping `%` tolerates the extra key.

## F2 — V1 is incomplete: `FileExtensionValidator` omits `value` **[FIXED in V2]**

- **input:** `FileExtensionValidator(['txt'])(ContentFile('x', name='a.jpg'))` with a
  custom message `'%(value)s rejected'`.
- **observed (V1):** `params == {'extension': 'jpg', 'allowed_extensions': 'txt'}`;
  `%(value)s` → **`KeyError: 'value'`**.
- **expected (uniform spec):** `params['value']` is the `File`, so `%(value)s`
  renders (`str(File)` is its name).
- **classification:** missing-postcondition / consistency gap (PO1).
- **fix:** add `'value': value` to the single `FileExtensionValidator` raise.

## F3 — `URLValidator` IDN retry reports the normalized URL, not the provided value **[FIXED in V2]**

- **input:** an invalid internationalized-domain URL `u` whose `netloc` is changed
  by `punycode()` (IDN → ACE), e.g. one that still fails after normalization, with a
  custom message `'%(value)s is not a valid URL'`.
- **observed (V1):** the value reaches the IDN branch; `super().__call__(url)` is
  called with the **ACE-normalized** `url`, and `RegexValidator` raises with
  `params['value'] == url` (e.g. `http://…xn--…`). The user sees the punycode form,
  not what they submitted.
- **expected (PO5, value-identity):** `params['value']` is the value **as provided**.
- **classification:** value-identity violation (PO5) on one sub-path. *Severity is
  low* — for non-IDN inputs `urlunsplit(urlsplit(value)) == value`, so the common
  reject cases already report the original value; only true IDN/normalizing inputs
  diverge, and the existing suite never inspects URL params. But the clean contract
  is “the provided value,” so this is a real (if narrow) finding.
- **fix:** wrap the IDN-retry `super().__call__(url)` in `try/except ValidationError`
  and `raise e` (the original failure, which already carries
  `params={'value': value}` with the *provided* value). This is symmetric with the
  adjacent `except UnicodeError: raise e` and changes nothing on the success path.

## F4 — Rendering now runs for messages it skipped before: bare `%` in a *custom* message raises **[ACCEPTED]**

- **input:** a custom message with an unescaped literal percent and no params
  intent, e.g. `RegexValidator(regex=r'\d+', message='must be 100% numeric')('x')`.
- **observed (pre-fix):** `params is None`, so `ValidationError.__iter__` **skips**
  `message %= params`; the message renders verbatim → `'must be 100% numeric'`.
- **observed (after fix):** `params == {'value': 'x'}` is truthy, so `__iter__` runs
  `'must be 100% numeric' % {'value': 'x'}` → **`ValueError: unsupported format
  character`** (the `% n` is read as a conversion).
- **expected / decision:** this is a genuine behaviour change, but it is **[ACCEPTED]**,
  not fixed, because:
  1. It is **already** the behaviour of `BaseValidator` and its subclasses
     (`Max/MinValueValidator`, `Max/MinLengthValidator`), which have *always* passed
     `params`; the fix merely makes the rest of the validators consistent with that
     long-standing precedent.
  2. Django’s documented convention is that an error `message` combined with params
     must escape a literal percent as `%%`. A bare `%` alongside params is already
     “incorrect” usage.
  3. **No built-in default message contains a bare `%`** (enumerated in
     PROOF.md §4), so PO3/RENDER-DEFAULT holds and there is **no regression for any
     default message** or any existing test.
  - A validator-level mitigation is impossible without changing
    `ValidationError.__iter__` (out of scope and it would affect `BaseValidator`
    identically). Documented as residual risk in PROOF.md §6.

## F5 — Positive finding: the change is additive and rendering-invariant **[CONFIRMED]**

- **(CONTRACT-ACCEPT, PO2):** every guard predicate `invalid(value)` is untouched;
  no raise was added on an accept path. `input: any value the validator accepts →
  observed: returns None, raises nothing → expected: unchanged`. ✔
- **(RENDER-DEFAULT, PO3):** every built-in default message has `noPercent = true`,
  so `m % {'value': …} == m`. `input: any default message → observed: identical
  rendered text → expected: unchanged`. ✔
- **(deconstruct/migrations):** `params` is built per-call inside `__call__`; it is
  **not** stored on the instance, so `@deconstructible` serialization and validator
  `__eq__` are unaffected. `input: deconstruct(MaxLengthValidator(10)) → observed:
  unchanged → expected: unchanged`. ✔
- **(no double interpolation):** `__iter__` does `message = error.message; message
  %= error.params`, rebinding a *local*; `error.message` is never mutated, so
  repeated `.messages` access re-renders from the original. ✔

## F6 — `DecimalValidator`’s NaN/`invalid` branch has no `code` **[OUT OF SCOPE]**

- **input:** `DecimalValidator(1, 0)(Decimal('NaN'))`.
- **observed:** raises with `code is None` (every other Decimal branch sets a code).
- **note:** a pre-existing latent inconsistency, unrelated to this issue. The V2
  change adds `params={'value': value}` here for uniformity but **deliberately does
  not** add a `code` (that would change `e.code` from `None` and risks an unrelated
  test). Flagged for a future ticket, not fixed here.

---

## Proof-derived findings from `/verify`

Constructing the proof (PROOF.md) produced no new *correctness* obstacles beyond
F1–F4. One **capability** boundary was hit and named, not faked:

- **[ESCALATION BOUNDARY] — full `str.__mod__` mapping semantics.** The proof needs
  only one slice of Python’s `%`-interpolation: *no `%` in the message ⇒ identity*
  (PO3). That slice is modelled and discharged. The general behaviour
  (placeholder substitution, `%%` escaping, the bare-`%` `ValueError` of F4, and the
  “mapping tolerates unused keys” rule) is the real `str.__mod__`/`gettext` lazy-mod
  semantics, outside the bundled arithmetic+map tier. It is stated as a boundary, not
  admitted as `[trusted]`. This does not weaken F1–F5, which are about *which keys
  the params map contains* and *whether a raise happens* — pure control-flow/map facts.
