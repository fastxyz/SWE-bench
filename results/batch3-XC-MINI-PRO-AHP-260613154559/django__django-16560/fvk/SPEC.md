# SPEC.md — formal specification of the V1 fix (django__django-16560)

**Target intent (from `benchmark/PROBLEM.md`):** allow customizing the `code`
attribute of the `ValidationError` raised by `BaseConstraint.validate`, mirroring
the existing `violation_error_message` mechanism and the `code`/`message` pairing
that form/field validators already use.

**Code under specification (V1 fix):** the additions of a `violation_error_code`
parameter/attribute across `django/db/models/constraints.py` (`BaseConstraint`,
`CheckConstraint`, `UniqueConstraint`) and
`django/contrib/postgres/constraints.py` (`ExclusionConstraint`).

Default mode is **partial correctness** (a contract holds *if/when* the modeled
method returns). The changed code is **loop-free and recursion-free** straight-line
code with `if x is not None` guards, so no loop invariant / circularity is needed —
see `PROOF.md`. The mini-Python fragment is in `fvk/constraints.k`; the K claims are
in `fvk/constraints-spec.k`.

Throughout, let `C` be the symbolic value supplied as `violation_error_code`
(`C = null` models the default `None`). "Effective code" means *the instance
attribute if set, otherwise the class attribute `violation_error_code = None`*.

---

## Function/method contracts (reachability rules `φ_pre ⇒ φ_post`)

### C1 — `BaseConstraint.__init__` (code slice)  → claim `(INIT-CODE)`
- **Pre:** called with `violation_error_code = C` (any value, including `null`).
  The relevant statement is
  `if violation_error_code is not None: self.violation_error_code = violation_error_code`.
- **Post:** the *effective code* of the constructed object equals `C`.
  - Proof-relevant case split: `C = null` ⇒ guard false ⇒ instance attr unset ⇒
    reads class default `None = C`. `C ≠ null` ⇒ guard true ⇒ instance attr `= C`.
  - **This postcondition is clean and universal** (holds for *all* `C`). No
    precondition is required. (Positive signal — see `FINDINGS.md` F4.)
- **Backward-compat side obligation:** the `violation_error_message` handling is
  byte-for-byte unchanged; the new code is inserted *before* it and writes a
  different attribute, so message behavior is preserved (PO2).

### C2 — `BaseConstraint.deconstruct` (code slice)  → claim `(DECON-CODE)`
- **Pre:** object with effective code `C`. Statement:
  `if self.violation_error_code is not None: kwargs["violation_error_code"] = self.violation_error_code`.
- **Post:** reading the produced `kwargs` *with default `None`* yields `C`:
  - `C = null` ⇒ key absent ⇒ `kwargs.get("violation_error_code", None) = None = C`.
  - `C ≠ null` ⇒ key present `= C`.
- **Backward-compat side obligation (PO4):** when `C = null`, `kwargs` is identical
  to the pre-fix output (no extra key), so existing deconstruction tests are
  unaffected. The two subclass `deconstruct()` overrides call `super().deconstruct()`
  and only *add* their own keys, so they inherit C2 unchanged.

### C3 — `clone` round-trip  → claim `(ROUNDTRIP-CODE)`
- `clone(c) = type(c)(**c.deconstruct()[2])`.
- **Post:** `clone(c)` has effective code equal to `c`'s effective code, for all `C`
  (compose C2 then C1). Combined with the pre-existing round-trips of the other
  fields **and** with EQ including the code (C5), `clone(c) == c` (PO6).
- **This is the central correctness obligation:** adding the code to `__eq__`
  *without* also emitting it from `deconstruct` would silently break `clone()` and
  migration serialization for custom-code constraints. V1 does both. (FINDINGS F3.)

### C4 — `validate` in-domain raise  → claim `(VALIDATE-CODE)`
- Applies to `CheckConstraint.validate`, `ExclusionConstraint.validate` (both
  branches), and `UniqueConstraint.validate` **expressions** and **condition**
  branches. On a detected violation the code raises
  `ValidationError(self.get_violation_error_message(), code=self.violation_error_code)`.
- **Post:** the raised error's `.code` equals the effective code `C`, and its
  `.message` equals `get_violation_error_message()` (the message path is unchanged).
- **Pre / scope:** "a violation was detected" — the loop/query prefix that decides
  this is unchanged by the fix and is treated as opaque framing (it runs *before*
  the raise). `get_violation_error_message()` is total here (returns a string).

### C5 — `__eq__` includes the code  → claim `(EQ-CODE)`
- **Post:** for `CheckConstraint`, `UniqueConstraint`, `ExclusionConstraint`,
  `c1 == c2` implies (among the existing conjuncts) `c1.violation_error_code ==
  c2.violation_error_code`. Hence two constraints differing *only* in code are
  unequal. Symmetric/consistent with the existing `violation_error_message` conjunct.

### C6 — `__repr__` backward-compatibility + faithfulness  (read-off obligation)
- **Post (PO11):** when `C = null` the repr is byte-identical to the pre-fix repr
  (the code slot renders `""`), so existing `test_repr*` expectations hold.
- **Post (PO12):** when `C ≠ null` the repr contains
  `" violation_error_code=%r" % C`, placed before the message slot.

---

## Domain / assumptions

- `violation_error_code` is expected to be a short string identifier or `None`
  (like a validator `code`). Migration serialization (C2 feeding Django's migration
  writer) assumes a serializable value; this is the user's responsibility and is
  identical to the long-standing assumption on `violation_error_message`. See
  `FINDINGS.md` F6.
- The deprecated positional-argument branch of `__init__` (`*args`) is **not** part
  of the verified domain: `violation_error_code` is keyword-only by design. On the
  verified (keyword) domain the `if args:` block is a no-op. See `FINDINGS.md` F1.
- `UniqueConstraint` defined with `fields` and **no** `condition` is **outside** the
  domain of C4: that branch deliberately raises `instance.unique_error_message(...)`
  (codes `"unique"`/`"unique_together"`) and ignores both `violation_error_code` and
  `violation_error_message`, for backward compatibility. See `FINDINGS.md` F5.
