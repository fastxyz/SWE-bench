requires "mini-pyplot-cmap.k"

module PYPLOT-SET-CMAP-SPEC
  imports MINI-PYPLOT-CMAP
  imports MAP
  imports STRING
  imports BOOL
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - from_prompt: "I expected to be able to refer to my newly registered
  //   colormap by the name `my_cmap_name`." => set_cmap(str(alias)) stores the
  //   registered alias, not the Colormap object's internal name.
  // - from_docs: "The colormap name can then be used as a string argument to
  //   any `cmap` parameter in Matplotlib." => alias lookup is the public
  //   contract after registration.
  // - from_code: registry lookup returns a Colormap copy whose internal name
  //   may differ from the registry key.
  claim
    <k> setCmap(str(ALIAS:String)) ~> defaultCmap => C:CMap ... </k>
    <registry> REG:Map </registry>
    <rcCmap> RC:RcCmap => rcName(ALIAS) </rcCmap>
    <currentImage> noImage </currentImage>
    <imageCmaps> M:Map </imageCmaps>
    requires hasKey(REG, ALIAS)
     andBool lookup(REG, ALIAS) ==K C
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "plt.set_cmap('my_cmap_name')  # All OK setting the cmap"
  //   followed by imshow using the default => future image creation must be
  //   able to resolve the same registered alias.
  // - from_docs: pyplot.set_cmap "applies it to the current image if any" =>
  //   existing image branch updates to the resolved Colormap.
  claim
    <k> setCmap(str(ALIAS:String)) => .K ... </k>
    <registry> REG:Map </registry>
    <rcCmap> RC:RcCmap => rcName(ALIAS) </rcCmap>
    <currentImage> image(IMG:String) </currentImage>
    <imageCmaps> M:Map => M [ IMG <- C:CMap ] </imageCmaps>
    requires hasKey(REG, ALIAS)
     andBool lookup(REG, ALIAS) ==K C
    [all-path]

  // SPEC-PROVENANCE:
  // - from_pyplot_docstring: "cmap : Colormap or str" => a Colormap instance
  //   is a valid set_cmap input.
  // - from_whats_new_3_4: "It is now possible to set image.cmap to a Colormap
  //   instance" => storing the object in rcParams is public behavior.
  claim
    <k> setCmap(obj(C:CMap)) ~> defaultCmap => C ... </k>
    <registry> REG:Map </registry>
    <rcCmap> RC:RcCmap => rcObj(C) </rcCmap>
    <currentImage> noImage </currentImage>
    <imageCmaps> M:Map </imageCmaps>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_cm_docstring: get_cmap(None) returns the Colormap defined in
  //   image.cmap.
  // - from_rcsetup: image.cmap validates str or Colormap.
  claim
    <k> defaultCmap => C:CMap ... </k>
    <registry> REG:Map </registry>
    <rcCmap> rcObj(C) </rcCmap>
    <currentImage> I:MaybeImage </currentImage>
    <imageCmaps> M:Map </imageCmaps>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_cm._ensure_cmap comment: check_in_list preserves ValueError vs
  //   KeyError for invalid names.
  // - from_code_order: set_cmap calls get_cmap before rc() and before gci().
  claim
    <k> setCmap(str(BAD:String)) => unknownCmap ... </k>
    <registry> REG:Map </registry>
    <rcCmap> RC:RcCmap => RC </rcCmap>
    <currentImage> I:MaybeImage </currentImage>
    <imageCmaps> M:Map => M </imageCmaps>
    requires notBool hasKey(REG, BAD)
    [all-path]
endmodule
