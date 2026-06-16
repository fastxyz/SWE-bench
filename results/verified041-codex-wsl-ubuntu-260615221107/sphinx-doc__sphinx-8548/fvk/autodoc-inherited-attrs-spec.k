requires "mini-autodoc.k"

module AUTODOC-INHERITED-ATTRS-SPEC
  imports MINI-AUTODOC

  // SPEC-PROVENANCE:
  // - from_prompt: "autodoc inherited-members won't work for inherited
  //   attributes (data members)" => inherited documented data attributes must
  //   be selected by autoclass :inherited-members:.
  // - from_prompt: "autodoc searches for a cached docstring using
  //   (namespace, attrname) as search-key, but doesn't check for
  //   baseclass-namespace" => lookup must include base-class namespace.
  // - from_prompt: "parser ... parses only one module. It should also parses
  //   modules of all parent classes" => lookup ranges over MRO modules.
  // - from_default_domain: Python attribute resolution follows class MRO.
  claim <k> collectMembers(Inherited, Inherited , Base , .Classes,
                           owner(ham, class(Base)) , .Owners,
                           attrdoc(Base, ham, "A base attribute.") , .AttrDocs)
        => member(ham, class(Base), runtime, doc("A base attribute.")) , .Members
        </k>

  // SPEC-PROVENANCE:
  // - from_prompt: "Base.ham attribute is not present ... However, Base.eggs
  //   inherited method is displayed" => documented inherited attributes must
  //   participate in filtering like documented members.
  claim <k> selectedAsAttribute(
              member(ham, class(Base), runtime, doc("A base attribute.")) , .Members,
              ham)
        => true
        </k>

  // SPEC-PROVENANCE:
  // - from_prompt: "even using autoattribute does not work" => explicit
  //   autoattribute on the subclass path must render the base-class comment.
  claim <k> attributeContent(Inherited, ham,
                             attrdoc(Base, ham, "A base attribute.") , .AttrDocs,
                             owner(ham, class(Base)) , .Owners)
        => doc("A base attribute.")
        </k>

  // SPEC-PROVENANCE:
  // - from_default_domain: a subclass attribute definition shadows a base
  //   attribute in Python MRO.
  // - from_intent: inherited docs apply to inherited members, not to a distinct
  //   subclass attribute with the same name.
  claim <k> attributeContent(Inherited, ham,
                             attrdoc(Base, ham, "A base attribute.") , .AttrDocs,
                             owner(ham, class(Inherited)) , .Owners)
        => .NoDoc
        </k>
endmodule

