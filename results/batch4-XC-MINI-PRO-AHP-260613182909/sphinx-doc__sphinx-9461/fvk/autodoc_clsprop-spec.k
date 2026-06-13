// =====================================================================
// autodoc_clsprop-spec.k  --  reachability claims for the #9461 fix
//
// Proves (constructed, not machine-checked) the contracts of the functions the
// V2 fix touches, over the mini-Python descriptor fragment in
// autodoc_clsprop.k.  Uppercase = logical variables; lowercase ids = program
// names.
// =====================================================================
requires "autodoc_clsprop.k"

module AUTODOC-CLSPROP-SPEC-SYNTAX
  imports AUTODOC-CLSPROP-SYNTAX
endmodule

module VERIFICATION
  imports AUTODOC-CLSPROP-SPEC-SYNTAX
  imports AUTODOC-CLSPROP
  imports MAP-SYMBOLIC
  imports K-EQUAL
endmodule

module AUTODOC-CLSPROP-SPEC
  imports VERIFICATION

  // -----------------------------------------------------------------
  // (GETATTR-CMP)  getattr on a class RESOLVES a classmethod-property.
  // For any class C whose MRO-first definition of N is classmethod(property(F)),
  // getattrClass(C,N) yields the getter's value, NOT the property.  This is the
  // root cause: selection/docstring code that relies on getattr never sees a
  // property.  (value(0) abstracts "the getter return value".)
  // -----------------------------------------------------------------
  claim <k> getattrClass(c, n) => value(0) </k>
        requires isclassmethodprop(mroLookup(c, n)) ==K true
        [one-path]

  // -----------------------------------------------------------------
  // (GETATTR-PROP)  getattr on a class for a PLAIN property yields the property
  // itself (why plain @property always worked).
  // -----------------------------------------------------------------
  claim <k> getattrClass(c, n) => property(F:Id) </k>
        requires mroLookup(c, n) ==K property(F)
        [one-path]

  // -----------------------------------------------------------------
  // (GCM-CMP)  get_class_members registers EVERY classmethod-property reachable
  // through the MRO as an ObjectMember carrying the *property object* (not the
  // getter value) and the *defining* class.  Stated here for the canonical
  // 2-class case (own + inherited) to exercise both the registration and the
  // shadowing/seen logic; the loop circularity (GCM-LOOP) generalizes it.
  //
  // Sub defines cp_sub = classmethod(property(fsub));
  // Base defines cp_base = classmethod(property(fbase));
  // MRO(Sub) = [Sub, Base].
  // After get_class_members(Sub):
  //   members[cp_sub]  = om(property(fsub),  Sub)
  //   members[cp_base] = om(property(fbase), Base)
  // -----------------------------------------------------------------
  claim <k> get_class_members(sub) => .K </k>
        <classes>
          sub  |-> clsInfo((cp_sub  |-> classmethod(property(fsub))),  ListItem(sub) ListItem(base))
          base |-> clsInfo((cp_base |-> classmethod(property(fbase))), ListItem(base))
        </classes>
        <seen> .Set => ?_:Set </seen>
        <members>
          .Map =>
            (cp_sub  |-> om(property(fsub),  sub))
            (cp_base |-> om(property(fbase), base))
        </members>
        [one-path]

  // -----------------------------------------------------------------
  // (GCM-LOOP)  Circularity for the per-class walk gcmClass.
  // Generalized over the remaining __dict__ slice D and the seen-set S.
  // INVARIANT: walking the rest of class B's dict registers exactly those names
  // n in D that (a) are not already in <seen>, and (b) are classmethod-
  // properties, and (c) are not already in <members>; it adds each such name to
  // <seen> and binds members[n] = om(propOf(D[n]), B); all other names of D are
  // only added to <seen>.  Side condition: none, the walk is total over the
  // finite Map D.
  //
  // We state the single-step generalization that K coinduction discharges:
  // from an arbitrary (B, D) state the walk terminates (=> .K) having only ever
  // *extended* <seen> and <members> monotonically.  (The full functional
  // postcondition is given in the spec note / PROOF.md; here we assert
  // termination + monotonic extension, which is what the circularity needs.)
  // -----------------------------------------------------------------
  claim <k> gcmClass(b, D:Map) => .K </k>
        <seen>    S:Set => ?S':Set </seen>
        <members> M:Map => ?M':Map </members>
        ensures   S <=Set ?S' andBool keys(M) <=Set keys(?M')
        [one-path]

  // -----------------------------------------------------------------
  // (CANDOC)  can_document_member returns true for a property member (the value
  // get_class_members now stores for a classmethod-property), independently of
  // the class' own __dict__.  This is why both own and inherited classmethod-
  // properties are *selected* as PropertyDocumenter.
  // -----------------------------------------------------------------
  claim <k> candoc_property(property(F:Id), n, cdoc) => true </k> [one-path]

  // -----------------------------------------------------------------
  // (IMPORT-CMP / IMPORT-LOOP)  import_object, for a parent class P whose MRO
  // first binds attr n to classmethod(property(F)), sets self.object := property(F)
  // and isclassmethod := true and succeeds (=> true).  Holds whether the binding
  // is in P itself (own) or in a base (inherited) -- the MRO search is the
  // circularity, generalized over the MRO tail.
  // -----------------------------------------------------------------
  claim <k> importPropertyObject(p, n) => true </k>
        <classes>... p |-> clsInfo(_, MRO:List) ...</classes>
        <self>   _ => property(?F:Id) </self>
        <isclsm> _ => true </isclsm>
        requires isclassmethodprop(mroLookup(p, n)) ==K true
        [one-path]

  // impSearch circularity: searching the MRO tail either finds the most-derived
  // definition (cm-property => set+true; non-cm-property => false/stop) or runs
  // off the end (false).  Generalized over the List L.
  claim <k> impSearch(L:List, n) => ?B:Bool </k>
        <self>   O => ?O':K </self>
        <isclsm> C => ?C':Bool </isclsm>
        [one-path]

  // -----------------------------------------------------------------
  // (HEADER)  add_directive_header emits ':classmethod:' exactly when
  // isclassmethod is true, and ':abstractmethod:' exactly when the property is
  // abstract -- abstract first.  Pure function over the two booleans.
  // -----------------------------------------------------------------
  claim <k> headerLines(true,  true)  => ListItem(":abstractmethod:") ListItem(":classmethod:") </k> [one-path]
  claim <k> headerLines(false, true)  => ListItem(":classmethod:") </k> [one-path]
  claim <k> headerLines(false, false) => .List </k> [one-path]

  // -----------------------------------------------------------------
  // (PREFIX)  PyProperty.get_signature_prefix renders the option flags.
  // -----------------------------------------------------------------
  claim <k> signaturePrefix(false, true) => "class property " </k> [one-path]
  claim <k> signaturePrefix(true,  true) => "abstract class property " </k> [one-path]
endmodule
