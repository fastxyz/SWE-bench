module MINI-PYPLOT-CMAP-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX
  imports MAP-SYNTAX

  syntax CMap ::= cmap(String, String)
  syntax Input ::= str(String) | obj(CMap)
  syntax RcCmap ::= rcName(String) | rcObj(CMap)
  syntax MaybeImage ::= noImage | image(String)
  syntax Stmt ::= "setCmap" "(" Input ")"
                | "defaultCmap"
                | "applySetCmap" "(" MaybeName "," CMap ")"
                | "updateImage" "(" CMap ")"
  syntax MaybeName ::= noName | someName(String)
  syntax KResult ::= CMap | RcCmap | MaybeImage | MaybeName | String
                   | "unknownCmap"

  syntax Bool ::= hasKey(Map, String) [function]
  syntax CMap ::= lookup(Map, String) [function]
endmodule

module MINI-PYPLOT-CMAP
  imports MINI-PYPLOT-CMAP-SYNTAX
  imports STRING
  imports BOOL
  imports MAP

  configuration
    <k> $PGM:Stmt </k>
    <registry> .Map </registry>
    <rcCmap> rcName("") </rcCmap>
    <currentImage> noImage </currentImage>
    <imageCmaps> .Map </imageCmaps>

  // Registered string path: mirrors pyplot.set_cmap preserving the original
  // string in cmap_name, then resolving it through get_cmap.
  rule <k> setCmap(str(N:String))
        => applySetCmap(someName(N), lookup(REG, N)) ... </k>
       <registry> REG:Map </registry>
    requires hasKey(REG, N)

  // Invalid string path: get_cmap/check_in_list fails before rc/image mutation.
  rule <k> setCmap(str(N:String)) => unknownCmap ... </k>
       <registry> REG:Map </registry>
    requires notBool hasKey(REG, N)

  // Colormap-object path: get_cmap returns the object itself.
  rule <k> setCmap(obj(C:CMap)) => applySetCmap(noName, C) ... </k>

  // rcParams assignment: strings store the registered key; objects store the
  // Colormap object, which is an allowed image.cmap value.
  rule <k> applySetCmap(someName(N:String), C:CMap)
        => updateImage(C) ... </k>
       <rcCmap> RC:RcCmap => rcName(N) </rcCmap>

  rule <k> applySetCmap(noName, C:CMap) => updateImage(C) ... </k>
       <rcCmap> RC:RcCmap => rcObj(C) </rcCmap>

  // Current image branch.
  rule <k> updateImage(C:CMap) => .K ... </k>
       <currentImage> noImage </currentImage>

  rule <k> updateImage(C:CMap) => .K ... </k>
       <currentImage> image(I:String) </currentImage>
       <imageCmaps> M:Map => M [ I <- C ] </imageCmaps>

  // Default colormap resolution used by ColormapRegistry.get_cmap(None) and
  // cm._ensure_cmap(None).
  rule <k> defaultCmap => lookup(REG, N) ... </k>
       <rcCmap> rcName(N:String) </rcCmap>
       <registry> REG:Map </registry>
    requires hasKey(REG, N)

  rule <k> defaultCmap => C:CMap ... </k>
       <rcCmap> rcObj(C) </rcCmap>
endmodule
