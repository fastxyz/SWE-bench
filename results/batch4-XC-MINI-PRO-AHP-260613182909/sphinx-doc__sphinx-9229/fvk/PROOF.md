# PROOF.md — constructed proof for the V1 fix (sphinx-doc__sphinx-9229)

> **Constructed, not machine-checked.** No `kompile`/`kprove` was run (no
> execution environment). Commands to machine-check are in §6. The proof is
> partial-correctness; here partial = total because the code is loop/recursion-free
> (§5).

## 0. Shape

Three loop-free contracts (`SPEC.md` §3) + one integration invariant (`SPEC.md`
§4). **No circularity / loop-invariant is used** — there is no loop and no
recursion, so guarded coinduction never appears. Each proof is a finite chain of
**Axiom** (a semantic rule fires), **Transitivity** (chain steps), **Case
Analysis** (`#Or` on a truthiness guard), and **Consequence** (discharge a side
condition). No arithmetic VC arises (no `/Int`, no symbolic products), so no
`[simplification]` lemma is needed — a notable simplification versus the `sum`
template.

---

## A. Proof of (GVC) — `get_variable_comment`

Goal: `A ⊢ φ_pre ⇒ φ_post`, with `φ_pre` the entry config and `φ_post` the
`<ret> ↦ C0>` config, `C0 = #oracleAttrDocs(M, K0)`,
`K0 = #pair(#join(#init(OP)), #last(OP))`, `requires OP ≠ .List` (PO-G1).

Symbolic execution against `mini-autodoc.k`:

1. `KEY = pair(join(init(self.objpath)), last(self.objpath))`
   - `self.objpath` reads `OP` from `<self>` (attr-read Axiom).
   - `init(OP) ⇒ #init(OP)`, `last(OP) ⇒ #last(OP)` (`last` defined since
     `OP ≠ .List`, PO-G1), `join(#init(OP)) ⇒ #join(#init(OP))`,
     `pair(…) ⇒ K0` (Axioms, seqstrict order). Bind `KEY ↦ K0` (assignment Axiom).
2. `ANALYZER = self.modname` → bind `ANALYZER ↦ M` (attr-read + assignment).
   *(`analyzer.analyze()` is an idempotent effect folded into the oracle PO-T1;
   it changes no cell we observe.)*
3. `return copy(attrdocs(ANALYZER, KEY))`
   - `attrdocs(M, K0) ⇒ #oracleAttrDocs(M, K0) = C0` (oracle Axiom, PO-T1).
   - `copy(C0) ⇒ C0` (value-equal shallow copy Axiom; this is the `list(...)`
     non-aliasing copy, FINDINGS F8).
   - `return C0` sets `<ret> ↦ C0` (return Axiom).

By **Transitivity** the chain reaches `φ_post`. **No VC** beyond PO-G1
(`OP ≠ .List`, Z3-trivial) and the trusted PO-T1/PO-T2. ∎ (constructed)

*The `except PycodeError` arm is not in this run:* it is the out-of-domain guard
(unanalyzable `M`), modeled by the oracle yielding `.List` — `(GVC)` then returns
`.List`, which is exactly `return []`. Either way the contract `result = C0`
holds (with `C0 = .List` in the guard case). FINDINGS F2.

---

## B. Proof of (GETDOC-COMMENT) and (GETDOC-NONE)

Both start from the alias body
`if (self.doc_as_attr) { COMMENT = «GVC»; if COMMENT { return wrap(COMMENT) } else { return None } } else { … }`
with `doc_as_attr ↦ true` in `<self>`.

1. `self.doc_as_attr ⇒ true` (attr-read Axiom); the outer `if true {…}` selects
   the alias arm (guard Axiom, `truthy(true)=true`). *(The non-alias `else` arm is
   never entered — PO-D4.)*
2. `COMMENT = «get_variable_comment»` ⇒ by lemma **(GVC)** (used here as an
   ordinary called-function contract, **not** a circularity), bind
   `COMMENT ↦ C0`. (Transitivity with §A.)
3. **Case Analysis** on `truthy(C0)` (`#Or`):
   - **branch C0 ≠ .List** (`truthy = true`): inner `if` takes the then-arm,
     `return wrap(C0) ⇒ return ListItem(C0) .List`, so `<ret> ↦ [C0]`. This is
     **(GETDOC-COMMENT)**. ∎
   - **branch C0 = .List** (`truthy = false`): inner `if` takes the else-arm,
     `return None`, so `<ret> ↦ None`. This is **(GETDOC-NONE)**. ∎

**Consequence / VC:** none beyond the truthiness decision, which is definitional
(`truthy(.List)=false`, `truthy(ListItem(_) _)=true`). The **only subtle VC** is
the **`None` vs `[]`** distinction (PO-D2): the else-arm returns the distinguished
`None`, not `.List`; checked against `add_content`'s `if docstrings is None: pass`.
Discharged by inspection. ∎ (constructed)

---

## C. Proof of (NO-DOUBLE) — the integration keystone (PO-I1)

Model `add_content`'s comment logic as
```
if analyzer_present { if (K0 in attrdocs(A, ·)) { render attrdocs(A,K0); no_docstring = true } }
if (not no_docstring) { d = get_doc(); if (d == None) {} else { render d } }
```
with `<out>` accumulating rendered blocks. **Case Analysis** on the predicate
`P ∧ (K0 ∈ attrdocs(A,·))` (PATH-1 fires?):

- **PATH-1 fires (true):** first `if` renders `attrdocs(A,K0)` into `<out>` and
  sets `no_docstring ↦ true` (Axioms). Second `if`: guard `not true = false` →
  body skipped (guard Axiom). `get_doc` **not evaluated**. `<out>` holds the
  comment **once**.
- **PATH-1 does not fire (false):** first `if` renders nothing,
  `no_docstring` stays `false`. Second `if`: guard `not false = true` →
  `d = get_doc()`; by **(GETDOC-COMMENT)/(GETDOC-NONE)** (Transitivity),
  `d = [C0]` (render once) or `d = None` (render none). `<out>` holds the comment
  **at most once**.

Both branches land in `#renderedBlocks` (`SPEC.md` §4 table) with render-count
∈ {0,1}. The branches are **disjoint** (a boolean and its negation) and
**exhaustive**, so over all executions the comment renders **never twice**. ∎
(constructed). This is the obstacle whose non-discharge would be the bug signal;
it **discharges** — confirming V1 (FINDINGS F4).

---

## 4. What's proved (plain language)

- **`get_variable_comment()`** returns exactly the alias's own doc-comment from
  its **defining** module `self.modname` (a fresh copy), or `[]` when there is
  none or the module is unanalyzable.
- **`get_doc()` for an alias** returns `[comment]` when the alias has its own
  comment, and `None` otherwise — never the aliased class's `__doc__`, and never
  `[]` (so a comment-less alias does not fire `autodoc-process-docstring`).
- **End-to-end**, an alias with a comment renders **comment + `alias of …`
  exactly once**; a comment-less alias renders **only `alias of …`**.

For the reporter's example, all three aliases now render their docstrings (the
two previously dropped were routed through `ClassDocumenter` because they were
`type` instances; they now recover their comment via `get_variable_comment`).

## 5. Residual risk

- **Partial vs total:** loop/recursion-free ⇒ trivially terminating ⇒ partial =
  total. No variant needed.
- **Trusted base:** PO-T1 (analyzer/parser oracle — upstream, unchanged by this
  fix), PO-T2 (key adequacy — same key the established path uses), PO-T3 (Python
  value/exception semantics; mini-Python fragment is an MVP stopgap, full
  Python-in-K is roadmap). The reachability metatheory + Z3/`kprove` are trusted
  as usual.
- **Constructed, not machine-checked** — see §6.
- **Known scope gap (not a regression):** re-exported aliases (FINDINGS F9).

## 6. Reproduce the machine check (constructed only)

```sh
kompile mini-autodoc.k --backend haskell          # compile the fragment semantics
kast    --backend haskell mini-autodoc-spec.k     # (optional) parse-check the claims
kprove  mini-autodoc-spec.k                        # expected: #Top  (all claims proved)
```
`#Top` from `kprove` would upgrade these results from *constructed* to
*machine-verified*. (The `.k`/`-spec.k` content is given inline in `SPEC.md` §2–§4;
it is intentionally not emitted as separate buildable files because no toolchain
is present to consume them.)

## 7. Test-redundancy recommendation (benefit 1) — **recommendation only**

Conditioned on machine-checking (§6); until then, **keep all tests**. Mapping the
contracts onto the visible suite:

- **Subsumed-in-principle (do NOT remove yet):**
  - `test_class_alias` (`Alias = Foo`, no comment → only `alias of Foo`, handler
    never fired) is entailed by **(GETDOC-NONE)** + **PO-I1/F5**. Keep until
    `kprove` returns `#Top` — and note it *also* pins the `None`≠`[]` /
    no-event behaviour (PO-D2), which is exactly the kind of guard test worth
    keeping regardless.
  - `test_autodoc_typed_instance_variables` (`Alias = Derived`, no comment) and
    `test_autodoc_inner_class` (`Outer.factory = dict`, `#` not `#:`) are
    entailed by **(GETDOC-NONE)**.
  - `test_autodata_GenericAlias` (comment + `alias of`) characterizes the
    `DataDocumenter` sibling behaviour V1 mirrors; **keep** — it is the oracle
    for intent I1 and lives outside the changed code.
- **Always keep:** any test of the unchanged non-alias `get_doc` path
  (`autoclass_content`, `class-doc-from`, init/new docstrings); integration/build
  tests; and any new hidden test exercising the **direct external-alias-with-comment**
  case (the F1 path) — that is precisely the previously-uncovered behaviour and
  must stay.

**Net CI estimate:** the fix subsumes *no* currently-removable test on its own
(the alias-no-comment tests double as `None`/event guards and as
out-of-the-changed-domain pins), so the honest recommendation is **0 removals**;
the value here is benefit 2 (the audit), not test pruning.

## 8. Verdict

Every behavioural and integration obligation **discharges** against the spec; the
only open items are upstream trusted-base boundaries unaffected by the fix. The
audit **confirms V1**; no source change is required (see `reports/fvk_notes.md`
for the one-line cosmetic comment-clarification decision and why it was kept
minimal).
