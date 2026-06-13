# PROOF.md — constructed correctness proof, sphinx-doc__sphinx-8548 (V1)

> **Constructed, not machine-checked.** No `kompile`/`kprove` was run (no execution
> environment, per task constraints). The proof is a symbolic-execution argument
> against the mini-K fragment in SPEC.md, discharging the obligations in
> PROOF_OBLIGATIONS.md. The exact run-commands to upgrade it to machine-checked are
> in §7.

## 1. What is proved (plain language)

1. **`get_attribute_comment(parent, A)`** returns the attribute comment of the
   *nearest* class in `parent`'s MRO that documents `A`, or `None` — for every
   MRO and every analyzer state. *(claim GAC)*
2. **`get_class_members`'s final MRO loop** transforms `members` into exactly
   `mergeAll(MRO, AD, members, 0)`: it adds source-only inherited instance
   attributes and completes the `None` docstrings of inherited class attributes
   from the nearest commenting class, never overwriting an existing docstring,
   skipping source-less (builtin) classes. *(claim GCM)*
3. **`AttributeDocumenter.get_doc`** returns the nearest-MRO comment if one exists
   and is **otherwise byte-for-byte the pre-fix behavior**. *(claim GD, esp.
   GD-EQ)*

Together (1)+(2) make the inherited attribute `ham` *kept* by `filter_members`
(its `ObjectMember.docstring` is now non-empty ⇒ `has_doc = True`), and (1)+(3)
make the per-attribute documenter *emit* `Base`'s comment. That is exactly the bug
in FINDINGS F1.

## 2. The function claim (GAC) and its proof

Claim `(GAC)` (SPEC.md §2): from `<i> 0 </i>, <ret> NONE </ret>`,
`getAttrComment(P,A)` reaches `<ret> R </ret>` with
`R = firstComment(MRO, AD, A, 0)`.

**Proof.** `(GAC)` is `(GAC-LOOP)` instantiated at `I = 0` (GAC-VC5); its side
condition `0 ≤ 0 ≤ size(MRO)` holds. So it suffices to prove the circularity.

## 3. The loop circularity (GAC-LOOP) — guarded coinduction

Claim: from `<i> I </i>` with `0 ≤ I ≤ size(MRO)`, reach `<ret> R </ret>` with
`R = firstComment(MRO,AD,A,I)`.

**Proof by guarded coinduction** (the Circularity rule). Add `(GAC-LOOP)` to the
hypotheses; it may be used only after ≥1 genuine `=>` step.

- **Case `I ≥ size(MRO)`** (rule (i)): one Axiom step to `ret NONE`. By
  `firstComment` clause 1, `firstComment(…,I) = NONE`. Land on post. *(GAC-VC3)*
- **Case `I < size(MRO)` ∧ `definedAD(MRO,AD,I,A)`** (rule (ii)): one Axiom step to
  `ret ADlookup(I,A)`. By clause 2, that equals `firstComment(…,I)`. *(GAC-VC2)*
- **Case `I < size(MRO)` ∧ `¬definedAD(…)`** (rule (iii)): one **genuine** Axiom
  step `I := I+1` (this discharges guardedness, GAC-VC4). Now `0 ≤ I+1 ≤ size(MRO)`
  holds, so **invoke the circularity** at `I+1`, yielding
  `R = firstComment(…,I+1)`. By clause 3, `firstComment(…,I) = firstComment(…,I+1)`
  (since `¬definedAD`). Land on post. *(GAC-VC1)*

Case Analysis (`#Or` over the three guards) composes the branches; Consequence
discharges the def-equalities; Transitivity chains the step with the coinductive
result. ∎

`firstComment` plays the role the classical loop invariant used to play (the
"running result so far"), exactly as the sum example's closed form does.

## 4. `get_class_members` merge loop (GCM) and `get_doc` (GD)

**(GCM)** is the same shape: outer circularity `(GCM-LOOP)` folding the MRO, with
the inner `(GCM-INNER)` finite-fold used as a lemma (nested circularities, as in
the insertion-sort example). The three reachable outer branches map 1-1 to
PROOF_OBLIGATIONS §B:

- exhausted ⇒ `mergeAll` clause 1 (Reflexive close, post = `M`);
- `noSource` ⇒ genuine step `I:=I+1`, invoke circularity ⇒ clause 2
  (GCM-VC-skip);
- has-source ⇒ run `(GCM-INNER)` as a lemma to get `mergeClass(…,I)`, genuine step
  `I:=I+1`, invoke circularity ⇒ clause 3 (GCM-VC-add/-complete/-preserve).

The decisive structural lemma is **first-write-/first-doc-wins** of a left fold
(GCM-VC-add, GCM-VC-idem): because the outer fold visits classes in MRO order and
the inner update is *guarded by* `a ∉ dom(M)` (insert) or `M[a].doc == NONE`
(complete), the value that survives is the one from the **least** MRO index — i.e.
the most-derived class. Idempotence (GCM-VC-idem) is what lets the same name be
commented in several base classes without ambiguity. These are discharged by the
map-update / fold-idempotence simplification lemmas (the analogues of the sum
example's map-extensionality lemma), plus Z3 for the index bounds.

**(GD)** is loop-free, a 2-guard composition. The crux is **GD-EQ**: on
`firstComment(MRO,AD,A,0) = NONE`, the added prefix `if comment: return [comment]`
with `comment = None` is dead, so V1 `get_doc` ≡ V0 `get_doc` **syntactically**.
Hence on the entire no-comment input space V1's observable behavior equals V0's —
the formal no-regression guarantee. On the comment branch, GD-COMMENT shows the
emission agrees with `Documenter.add_content`'s established comment-over-docstring
priority and is single (no double emission for local attributes, because the local
`attr_docs[(namespace,A)]` path in `add_content` fires first and skips `get_doc`).

## 5. Residual risk

- **Partial correctness.** Termination (GAC-TERM/GCM-TERM, measures
  `size(MRO)−I`, `|S|`) is argued in PROOF_OBLIGATIONS §D but the default proof is
  partial. Both loops are over finite, non-growing collections, so termination is
  not in real doubt.
- **Trusted base.** (a) **Fragment adequacy** — the analyzer oracle `AD` and the
  `noSource` abstraction of `PycodeError`/`try-except-continue` (FINDINGS **F-A**,
  an explicit **[ESCALATION BOUNDARY]**, not a `[trusted]` fake). (b) The
  reachability metatheory + `kprove`. (c) The map/Z3 simplification oracle.
- **Constructed, not machine-checked** — see §7.

## 6. Test-redundancy report (benefit 1) — recommendation only, NEVER auto-delete

Conditioned on running the §7 commands (the MVP does not machine-check). Note the
project test suite is **fixed and hidden** here, so these are *categories*, not
file edits, and **nothing is removed**.

- **Subsumed-if-machine-checked (could be thinned):** point tests that assert a
  *single* inherited-class-attribute renders its base comment (e.g.
  `Inherited.ham → "A base attribute."`) are entailed by `(GAC)`+`(GCM)` for the
  whole domain — one such case is representative once the claim is checked.
- **KEEP — out of contract / pin distinct behavior:**
  - the `:members:`+`:inherited-members:` **instance-attribute** case (FINDINGS
    **F2**, issue #6415) — *outside* the verified contract; pins a known
    limitation.
  - every **no-comment** attribute test (descriptors, `__slots__`, `TypeVar`,
    enum, `UNINITIALIZED_ATTR`, plain values) — these pin the **GD-EQ** branch
    where V1 must equal V0; they are the regression net for the fix.
  - **override-inherits-comment** (FINDINGS F3) behavior tests — pin a judgement
    call.
  - termination / integration / end-to-end tests.

Net: the fix is **test-net-positive** — it *adds* a provable contract but its main
value is that the large body of existing no-comment attribute tests is exactly the
GD-EQ regression net, so **keep them**.

## 7. Reproduce the machine check (constructed → machine-verified)

```sh
kompile autodoc-frag.k --backend haskell      # compile the mini-Python fragment
kast    --backend haskell autodoc-frag-spec.k # (optional) confirm the claims parse
kprove  autodoc-frag-spec.k                    # discharge GAC, GAC-LOOP, GCM, GCM-INNER, GD
#   expected: #Top  (all claims proved)
```

(The `.k` sources are embedded in SPEC.md §1–2; extract them to `autodoc-frag.k`
and `autodoc-frag-spec.k` to run the above. Until `kprove` returns `#Top`, treat
every "discharged" above as *constructed*.)

## 8. The two benefit payoffs

- **Benefit 2 (hidden bugs) — landed.** Formalizing surfaced F1 (the fixed bug,
  with a concrete failing input), F2 (a precise statement of the remaining
  instance-attribute limitation and *why* — `is_filtered_inherited_member` reaching
  `object`), and F3 (an intent question about overridden attributes). None required
  changing V1; all are documented rather than hidden.
- **Benefit 1 (fewer tests) — modest + honest.** The contract subsumes point
  "renders inherited comment" tests once machine-checked; but the dominant
  recommendation is to **keep** the no-comment attribute suite as the GD-EQ
  regression net. No deletions are advised pre-machine-check.
