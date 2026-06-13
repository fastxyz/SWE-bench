// =====================================================================
// autodoc_clsprop.k  --  mini-Python "descriptor + autodoc" fragment
//
// A deliberately minimal K semantics (an MVP "mini-X" fragment, per the FVK
// methodology) covering ONLY the constructs the V1/V2 fix for
// sphinx-doc/sphinx#9461 actually touches:
//
//   * class objects with a __dict__ (Map name |-> RawObj) and an MRO (List of
//     classes, most-derived first);
//   * the raw descriptor objects classmethod(_), property(_), and plain values;
//   * getattr() on a *class* implementing the Python >=3.9 descriptor protocol
//     where classmethod may wrap another descriptor (bpo-19072 / "Changed in
//     version 3.9");
//   * the autodoc member-discovery walk get_class_members();
//   * PropertyDocumenter.can_document_member / import_object / header emission;
//   * PyProperty.get_signature_prefix.
//
// Nothing else (no real Python statements, no exceptions, no I/O).  This is the
// stopgap the methodology describes; full Python-in-K is the roadmap.
// =====================================================================

module AUTODOC-CLSPROP-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX
  imports ID-SYNTAX

  // ---- raw objects that can live in a class __dict__ -------------------
  //   property(F)            : a property whose getter is the (opaque) F
  //   abstractproperty(F)    : a property whose fget is @abstractmethod
  //   classmethod(R)         : a classmethod wrapping raw object R
  //   func(F)                : an ordinary function
  //   value(V)               : a plain attribute value (int/str/...)
  syntax Raw ::= "property" "(" Id ")"
               | "abstractproperty" "(" Id ")"
               | "classmethod" "(" Raw ")"
               | "func" "(" Id ")"
               | "value" "(" Int ")"

  // ---- the operations the fix performs --------------------------------
  syntax KItem ::= "isproperty" "(" Raw ")"            [function]
                 | "isclassmethodprop" "(" Raw ")"     [function]
                 | "getattrClass" "(" Id "," Id ")"               // descriptor protocol
                 | "get_class_members" "(" Id ")"
                 | "candoc_property" "(" KItem "," Id "," Id ")"  // (member, name, classDoc)
                 | "importPropertyObject" "(" Id "," Id ")"       // (parentClass, attrName)
                 | "headerLines" "(" Bool "," Bool ")" [function] // (isAbstract, isClassmethod)
                 | "signaturePrefix" "(" Bool "," Bool ")" [function]

  syntax KResult ::= Bool | String | Raw
endmodule

module AUTODOC-CLSPROP
  imports AUTODOC-CLSPROP-SYNTAX
  imports INT
  imports BOOL
  imports STRING
  imports MAP
  imports LIST

  // ---------------------------------------------------------------------
  // Configuration.
  //   <classes> models the program: each class id |-> clsInfo(DICT, MRO)
  //     DICT : Map  (Id |-> Raw)        the class' own __dict__
  //     MRO  : List (of Id)             the method-resolution order,
  //                                     most-derived first, starting with self
  //   <members> is the result Map built by get_class_members:
  //     Id |-> om(VALUE:Raw, CLASS:Id)  (an ObjectMember; we keep value+class_)
  //   <out> collects emitted directive option lines.
  // ---------------------------------------------------------------------
  configuration
    <k> $PGM:K </k>
    <classes> .Map </classes>          // Id |-> clsInfo(Map, List)
    <members> .Map </members>          // Id |-> om(Raw, Id)
    <seen>    .Set </seen>             // names already considered by the MRO walk
    <self>    .K   </self>            // PropertyDocumenter.object
    <isclsm>  false:Bool </isclsm>    // PropertyDocumenter.isclassmethod
    <out>     .List </out>

  syntax KItem ::= "clsInfo" "(" Map "," List ")"
                 | "om" "(" Raw "," Id ")"

  // ===== isproperty / isclassmethodprop (pure predicates) ==============
  rule isproperty(property(_))         => true
  rule isproperty(abstractproperty(_)) => true
  rule isproperty(classmethod(_))      => false
  rule isproperty(func(_))             => false
  rule isproperty(value(_))            => false

  rule isclassmethodprop(classmethod(R)) => isproperty(R)
  rule isclassmethodprop(property(_))         => false
  rule isclassmethodprop(abstractproperty(_)) => false
  rule isclassmethodprop(func(_))             => false
  rule isclassmethodprop(value(_))            => false

  // ===== getattr() on a class: the Python >=3.9 descriptor protocol =====
  // We model the *observable* result type.  The only fact the proof needs is
  // that a classmethod-wrapped property is RESOLVED (getter invoked) and so does
  // NOT yield the property object -- it yields an opaque value(0) standing for
  // "the getter's return value".  A plain property on a class yields itself.
  //
  // mroLookup(C, N) returns the raw object from the first class in MRO(C) whose
  // __dict__ binds N, or #undef.
  syntax KItem ::= "mroLookup" "(" Id "," Id ")"           [function]
                 | "mroLookupL" "(" List "," Id ")"        [function]
                 | "#undef"
  rule [[ mroLookup(C, N) => mroLookupL(MRO, N) ]]
       <classes>... C |-> clsInfo(_, MRO) ...</classes>
  rule [[ mroLookupL(ListItem(B) REST, N) => D[N] ]]
       <classes>... B |-> clsInfo(D, _) ...</classes>
       requires N in_keys(D)
  rule [[ mroLookupL(ListItem(B) REST, N) => mroLookupL(REST, N) ]]
       <classes>... B |-> clsInfo(D, _) ...</classes>
       requires notBool (N in_keys(D))
  rule mroLookupL(.List, _) => #undef

  // getattrClass resolves to a Raw "as seen by autodoc selection".
  rule getattrClass(C, N) => value(0)
       requires isclassmethodprop(mroLookup(C, N)) ==K true          // 3.9 classmethod-property -> getter value
  rule getattrClass(C, N) => property(F)
       requires mroLookup(C, N) ==K property(F)                       // plain property -> itself
  rule getattrClass(C, N) => abstractproperty(F)
       requires mroLookup(C, N) ==K abstractproperty(F)
  // (other descriptor kinds are irrelevant to the property documenter and elided)

  // ===== headerLines / signaturePrefix (pure) ==========================
  // Order chosen by the fix: :abstractmethod: emitted before :classmethod:.
  rule headerLines(true,  true ) => ListItem(":abstractmethod:") ListItem(":classmethod:")
  rule headerLines(true,  false) => ListItem(":abstractmethod:")
  rule headerLines(false, true ) => ListItem(":classmethod:")
  rule headerLines(false, false) => .List

  rule signaturePrefix(true,  true ) => "abstract class property "
  rule signaturePrefix(true,  false) => "abstract property "
  rule signaturePrefix(false, true ) => "class property "
  rule signaturePrefix(false, false) => "property "

  // ===== can_document_member for PropertyDocumenter ====================
  // member is the ObjectMember.object passed by autodoc.  With the fix it is the
  // property object for a classmethod-property, so the first disjunct fires.
  rule candoc_property(MEMBER, _, _) => true
       requires isproperty({MEMBER}:>Raw) ==K true
  rule <k> candoc_property(MEMBER, N, CDOC) => isclassmethodprop(D[N]) ...</k>
       <classes>... CDOC |-> clsInfo(D, _) ...</classes>
       requires isproperty({MEMBER}:>Raw) ==K false andBool N in_keys(D)
  rule <k> candoc_property(MEMBER, N, CDOC) => false ...</k>
       <classes>... CDOC |-> clsInfo(D, _) ...</classes>
       requires isproperty({MEMBER}:>Raw) ==K false andBool notBool (N in_keys(D))

  // ===== get_class_members: the MRO walk that registers cm-properties ===
  // gcmWalk(MROlist, N-list...) is modeled as: for each class B in MRO (most
  // derived first), for each name in B.__dict__ not yet seen, if it is a
  // classmethod-property, register om(property-part, B).  We expose only the
  // cm-property registration (the part the fix adds); the subsequent dir()/other
  // loop and annotation loop are unchanged upstream behavior and are framed out.
  rule <k> get_class_members(C) => gcmWalk(MRO) ...</k>
       <classes>... C |-> clsInfo(_, MRO) ...</classes>

  syntax KItem ::= "gcmWalk" "(" List ")"
                 | "gcmClass" "(" Id "," Map ")"
  rule gcmWalk(.List) => .K
  rule <k> gcmWalk(ListItem(B) REST) => gcmClass(B, D) ~> gcmWalk(REST) ...</k>
       <classes>... B |-> clsInfo(D, _) ...</classes>

  rule gcmClass(_, .Map) => .K
  // name already seen by a more-derived class: skip entirely (shadowing)
  rule <k> gcmClass(B, (N |-> _) REST) => gcmClass(B, REST) ...</k>
       <seen> S </seen>
       requires N in S
  // not seen, IS a classmethod-property, not already a member: register it
  rule <k> gcmClass(B, (N |-> R) REST) => gcmClass(B, REST) ...</k>
       <seen> S => SetItem(N) S </seen>
       <members> M => M[N <- om(propOf(R), B)] </members>
       requires notBool (N in S) andBool isclassmethodprop(R) ==K true
                andBool notBool (N in_keys(M))
  // not seen, not a cm-property (or already a member): mark seen, register nothing
  rule <k> gcmClass(B, (N |-> R) REST) => gcmClass(B, REST) ...</k>
       <seen> S => SetItem(N) S </seen>
       <members> M </members>
       requires notBool (N in S)
                andBool (isclassmethodprop(R) ==K false orBool N in_keys(M))

  // propOf(classmethod(property(F))) = property(F)  (the obj.__func__)
  syntax Raw ::= "propOf" "(" Raw ")" [function]
  rule propOf(classmethod(R)) => R

  // ===== PropertyDocumenter.import_object (the MRO search) =============
  // After super().import_object, self.object is the getattr value (value(0))
  // for a classmethod-property; the fix searches the MRO for the raw object.
  rule <k> importPropertyObject(P, N) => impSearch(MRO, N) ...</k>
       <classes>... P |-> clsInfo(_, MRO) ...</classes>

  syntax KItem ::= "impSearch" "(" List "," Id ")"
  rule impSearch(.List, _) => false                      // not found anywhere -> import fails
  rule <k> impSearch(ListItem(B) REST, N) => impSearch(REST, N) ...</k>
       <classes>... B |-> clsInfo(D, _) ...</classes>
       requires notBool (N in_keys(D))                    // B doesn't define N: keep searching
  rule <k> impSearch(ListItem(B) REST, N) => true ...</k>
       <classes>... B |-> clsInfo(D, _) ...</classes>
       <self> _ => propOf(D[N]) </self>
       <isclsm> _ => true </isclsm>
       requires N in_keys(D) andBool isclassmethodprop(D[N]) ==K true   // found cm-property
  rule <k> impSearch(ListItem(B) REST, N) => false ...</k>
       <classes>... B |-> clsInfo(D, _) ...</classes>
       requires N in_keys(D) andBool isclassmethodprop(D[N]) ==K false  // shadowed by non-cm-prop: stop
endmodule
