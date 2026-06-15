# FINDINGS.md — parent-link selection (V1 audit)

Plain-language `input → observed vs expected`. Findings are independent of
machine-checking. References: [`SPEC.md`](SPEC.md) ledger E*, intent I*;
[`PROOF_OBLIGATIONS.md`](PROOF_OBLIGATIONS.md) O*.

## Confirmed-correct (the reported bug is fixed)

- **C1 — multiple OTOs, marked field wins, order-independent (O1).**
  `class Picking(Document)` with `document_ptr(parent_link=True)` + `origin`:
  - *Pre-V1:* `origin` (declared last) overwrote `parent_links[Document]` →
    `ImproperlyConfigured: Add parent_link=True to … origin`. Reverse order
    worked by accident.
  - *V1:* `document_ptr` is selected in **both** orders (PROOF §3 CASE-A/CASE-B).
    `input [True,False] → 1`, `input [False,True] → 2` — both the marked field.
    ✓ matches E1/E2/I1.
- **C2 — pk consistency (O5c).** `input` = marked field selected →
  `_meta.parents[Document]` == pk == `document_ptr`, so `document_ptr_id` is
  populated. Resolves the thread's "model still broken … unless field order is
  correct" follow-up (E4/I5). ✓

## Adequacy findings

- **F1 — lone unmarked OTO still errors: SUSPECT test, upheld on docs (O2).**
  *input* `class Picking(Document): some_unrelated = OneToOneField(Document)`
  (one OTO, no `parent_link`). *Observed (V1):* selected as the parent-link
  candidate → `Options._prepare()` raises `Add parent_link=True`. A thread
  comment (E5) calls this "the same … bug." Per the SUSPECT rule, `E5` and
  `test_missing_parent_link` (E8) were not allowed to veto intent — but the
  *positive* documentation evidence E6/E7 ("implicit promotion … deprecated …
  *Add `parent_link=True`*"; "removed" in 2.0) and the consumer error both
  require this behavior. **Expected == observed; V1 is correct to keep it.**
  This is intentionally *not* widened to the issue: the reported bug is about
  **multiple** references; the lone case is documented, deliberately-removed
  implicit promotion. *Classification:* underspecified intent in the thread,
  resolved by docs. (See F-ALT for the formal rejection of changing it.)

- **F-ALT — the "filter to `parent_link` only" alternative is falsified (O6).**
  The named alternative (`isinstance(field, OneToOneField) and
  field.remote_field.parent_link`, i.e. S. Charette's literal hint E3) was
  promoted to a tested hypothesis, **not** dropped on scope grounds. Side-by-side
  (PROOF §7): it agrees with V1 on the reported case but, on a lone unmarked
  field, returns "no selection" → the `Add parent_link=True` error becomes dead
  code and a `…_ptr` column is injected silently → **fails O2/E6** and breaks
  `test_missing_parent_link`. *Classification:* rejected alternative; V1's
  priority-not-filter design is forced. *(I tried exactly this filter form
  mid-audit in V1 development and reverted it for this reason.)*

## Lower-severity / edge findings

- **F2 — `reversed([new_class] + parents)` makes "first parent_link wins"
  parents-first.** *input:* a `parent_link` on an abstract base **and** a
  `parent_link` to the same parent on the child (two marked fields, cross-base).
  *Observed:* the abstract base's field wins (processed first; PROOF §4). *Intent:*
  undefined — declaring two parent links to one parent is not a documented
  configuration. *Classification:* edge/ambiguous, no public obligation; matches
  `test_abstract_parent_link` shape (E9) where only the abstract base is marked.
  No action.

- **F3 — two `parent_link=True` OTOs to the same parent (invalid input).**
  *input:* `link1(parent_link=True)` + `link2(parent_link=True)` to one parent.
  *Observed:* V1 picks `firstTrue` (= `link1`); pre-V1 picked the last. *Expected:*
  intent does not specify; this is user error (two parent links). *Classification:*
  out-of-domain (N2). Optional future hardening: a system check could flag
  "multiple parent links to the same parent," but that exceeds this issue and has
  no public-intent evidence. No action.

- **F4 — `existing.remote_field.parent_link` attribute access is safe.**
  *Probe:* could `existing` lack `.remote_field.parent_link`? *Observed:*
  `parent_links` values are only `OneToOneField`s (guarded by `isinstance`);
  `OneToOneField.remote_field` is a `OneToOneRel` with a `parent_link` attribute
  (the same attribute read at `base.py:214` and `options.py:254`). No
  `AttributeError`. Not a bug.

- **F5 — self-referential / non-parent OTOs are untouched.** *input:* an OTO to
  `self` or to an unrelated model. *Observed:* collected into `parent_links` under
  that target's key but never consulted unless the target is a concrete parent
  (`base.py:248`). Identical to pre-V1. Not a bug.

## Test-redundancy note (benefit 1) — recommendation only, conditioned on `kprove`

The constructed proof would (once machine-checked) subsume *in-domain* unit
assertions of the selection winner:
- `test_abstract_parent_link` (E9) → entailed by O1/O5b (marked field wins across
  a base). **Keep until `kprove` returns `#Top`** — it also exercises real
  metaclass wiring the mini-python fragment abstracts away.
- A new "multiple OTOs, both orders" test (the natural FAIL→PASS for this issue)
  → entailed by `(CASE-A)`/`(CASE-B)`. **Keep** (integration of `_prepare`).
- `test_missing_parent_link` (E8) → **KEEP unconditionally**: it pins O2, the
  out-of-domain boundary where F1/F-ALT bugs live. Never recommend its removal.

No deletions recommended now (constructed, not machine-checked; and all these
tests exercise real metaclass/`_prepare` wiring beyond the per-key fold).

## Proof-derived findings from `/verify`

- The proof needed **no** invented side condition beyond `J≥1` (positions are
  1-based) — a benign well-formedness fact, not a hidden precondition on the code.
  No "spec-difficulty" smell surfaced: the contract `selectResult` is clean and
  total, which is positive evidence the V1 logic is right.
- The only obstacle was the **adequacy** question F1/F-ALT (lone case), resolved
  by docs — surfaced as guidance, not a code change. See
  [`ITERATION_GUIDANCE.md`](ITERATION_GUIDANCE.md).
