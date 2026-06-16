// Constructed, not machine-checked.
// Formal claims for the export_text feature-name lookup control-flow fix.

requires "mini-export-text.k"

module EXPORT-TEXT-VERIFICATION
  imports MINI-EXPORT-TEXT
  imports K-EQUAL
  imports INT
  imports BOOL
  imports LIST

  syntax Bool ::= inList(Int, List) [function]
  rule inList(_X:Int, .List) => false
  rule inList(X:Int, ListItem(Y:Int) REST:List)
    => (X ==Int Y) orBool inList(X, REST)

  // Spec-only fitted-tree invariant for the structural tree abstraction:
  // every split feature is in range for the fitted feature count.
  syntax Bool ::= splitFeaturesInRange(Tree, Int) [function]
  rule splitFeaturesInRange(leaf, _LEN:Int) => true
  rule splitFeaturesInRange(split(FEATURE:Int, LEFT:Tree, RIGHT:Tree), LEN:Int)
    => 0 <=Int FEATURE
       andBool FEATURE <Int LEN
       andBool splitFeaturesInRange(LEFT, LEN)
       andBool splitFeaturesInRange(RIGHT, LEN)

  syntax Bool ::= splitFeaturesDefined(Tree) [function]
  rule splitFeaturesDefined(leaf) => true
  rule splitFeaturesDefined(split(FEATURE:Int, LEFT:Tree, RIGHT:Tree))
    => 0 <=Int FEATURE
       andBool splitFeaturesDefined(LEFT)
       andBool splitFeaturesDefined(RIGHT)
endmodule

module EXPORT-TEXT-SPEC
  imports EXPORT-TEXT-VERIFICATION

  // SPEC-PROVENANCE:
  // - from_prompt: "IndexError ... when there is single feature" => no bad
  //   lookup for a named one-feature fitted tree.
  // - from_prompt: "-2 indicates a leaf node" and "should never be accessing
  //   the feature name for a leaf" => lookup trace excludes TREE_UNDEFINED.
  // - from_docs: feature_names length equals n_features => named(NFEATURES).
  // - from_code: V1 performs lookupName only after split-node guard.
  // CLAIM: EXPORT-SAFE-NAMED
  claim
    <k> export(TREE:Tree, named(NFEATURES:Int), MAXDEPTH:Int) => .K </k>
    <names> noNames => named(NFEATURES) </names>
    <maxDepth> 10 => MAXDEPTH </maxDepth>
    <lookups> .List => LOOKUPS:List </lookups>
    <badLookup> false => false </badLookup>
    requires NFEATURES >=Int 1
     andBool splitFeaturesInRange(TREE, NFEATURES)
    ensures inList(-2, LOOKUPS) ==Bool false
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: if feature_names is None, generic names are used.
  // - from_prompt: leaves are not split nodes, so no generic feature_-2 label
  //   is produced by the split branch.
  // CLAIM: EXPORT-SAFE-GENERIC
  claim
    <k> export(TREE:Tree, noNames, MAXDEPTH:Int) => .K </k>
    <names> noNames => noNames </names>
    <maxDepth> 10 => MAXDEPTH </maxDepth>
    <lookups> .List => LOOKUPS:List </lookups>
    <badLookup> false => false </badLookup>
    requires splitFeaturesDefined(TREE)
    ensures inList(-2, LOOKUPS) ==Bool false
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "-2 indicates a leaf node" => leaf nodes do not look up
  //   feature names.
  // CLAIM: VISIT-LEAF-NO-LOOKUP
  claim
    <k> visit(leaf, DEPTH:Int) => .K </k>
    <names> NMS:Names </names>
    <maxDepth> MAXDEPTH:Int </maxDepth>
    <lookups> LOOKUPS:List => LOOKUPS </lookups>
    <badLookup> BAD:Bool => BAD </badLookup>
    requires DEPTH <=Int MAXDEPTH +Int 1
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: split node label is selected from the split feature index.
  // - from_code: V1 recurses after the split-node lookup.
  // CLAIM: VISIT-SPLIT-LOOKUP
  claim
    <k> visit(split(FEATURE:Int, LEFT:Tree, RIGHT:Tree), DEPTH:Int) => .K </k>
    <names> named(NFEATURES:Int) </names>
    <maxDepth> MAXDEPTH:Int </maxDepth>
    <lookups> LOOKUPS:List => FINALLOOKUPS:List </lookups>
    <badLookup> false => false </badLookup>
    requires DEPTH <=Int MAXDEPTH +Int 1
     andBool inList(-2, LOOKUPS) ==Bool false
     andBool 0 <=Int FEATURE
     andBool FEATURE <Int NFEATURES
     andBool splitFeaturesInRange(LEFT, NFEATURES)
     andBool splitFeaturesInRange(RIGHT, NFEATURES)
    ensures inList(-2, FINALLOOKUPS) ==Bool false
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code/docstring: max_depth truncation emits truncation/leaf text and
  //   does not need a feature name for the current node.
  // CLAIM: VISIT-TRUNCATED-NO-LOOKUP
  claim
    <k> visit(TREE:Tree, DEPTH:Int) => .K </k>
    <names> NMS:Names </names>
    <maxDepth> MAXDEPTH:Int </maxDepth>
    <lookups> LOOKUPS:List => LOOKUPS </lookups>
    <badLookup> BAD:Bool => BAD </badLookup>
    requires DEPTH >Int MAXDEPTH +Int 1
    [all-path]
endmodule
