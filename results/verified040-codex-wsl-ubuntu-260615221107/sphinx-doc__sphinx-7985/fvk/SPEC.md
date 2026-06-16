# FVK Specification: sphinx-doc__sphinx-7985

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Intent-Only Spec

The target behavior is the `linkcheck` builder's handling of link URI
classification and reporting.

- Local links are in scope. Public issue evidence: "linkcheck currently doesn't
  check local (internal) links" and "Expected results: Also a check for the
  local link."
- A missing relative local target must be reported as broken. Public issue
  evidence: the reproducer defines `.. _local-link: doesntexist`; the current
  observed output is `-local-   doesntexist`; the expected behavior is an actual
  check.
- The check is limited to Sphinx-known local material. Public hint evidence:
  "all we can check is only inside sphinx-document"; files added by a deploy
  script may be unknowable.
- Absolute local paths are not reliable to validate. Public hint evidence:
  "it is hard if local hyperlink is absolute path. We don't know where the
  document will be placed."
- The feature may be optional. Public hint evidence: "At least this could be an
  optional feature."
- Existing external link behavior must be preserved. Public docs describe
  `linkcheck_ignore`, retries, auth, request headers, redirects, and remote
  anchor checking.
- Anchor checking remains controlled by `linkcheck_anchors` and
  `linkcheck_anchors_ignore`. Public docs say `linkcheck_anchors` checks the
  validity of `#anchor`s, and `linkcheck_anchors_ignore` skips matching anchors.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| IE1 | issue | "linkcheck currently doesn't check local (internal) links" | Non-HTTP local `refuri` values must no longer be unconditionally accepted as `local`. | encoded |
| IE2 | issue | `.. _local-link: doesntexist` plus expected "Also a check" | A missing relative local target such as `doesntexist` is `broken`. | encoded |
| IE3 | hint | "only inside sphinx-document" | Valid local targets are Sphinx documents and local files the source tree can see; unknown deployment additions are outside the check. | encoded |
| IE4 | hint | "hard if local hyperlink is absolute path" | Absolute local links are left as `local`, not broken. | encoded |
| IE5 | hint | "optional feature" | Provide an opt-out configuration flag. | encoded as `linkcheck_local_links` |
| IE6 | docs | `linkcheck_anchors` checks `#anchor`s | Local document anchors must be checked when local checking and anchor checking are both enabled. | encoded |
| IE7 | docs | `linkcheck_anchors_ignore` skips matching anchors | Ignored local anchors must not become broken. | encoded |
| IE8 | docs/code | existing external HTTP checking | HTTP(S) network checking, caches, ignore handling, and output formats are frame conditions. | preserved |

## Domain Model

The local-link proof models the state available at `linkcheck` write time:

- `URI`: a string from a `nodes.reference['refuri']`.
- `DOC`: the source document currently being written.
- `LOCAL_LINKS`: the Boolean `linkcheck_local_links`.
- `ANCHORS`: the Boolean `linkcheck_anchors`.
- `IGNORE`: the set of compiled `linkcheck_ignore` patterns.
- `ANCHORS_IGNORE`: the set of compiled `linkcheck_anchors_ignore` patterns.
- `DOC_URI`: a finite map from generated local document URI to docname, built
  from `env.found_docs` using `quote(docname) + link_suffix` and its unquoted
  form.
- `DOC_ANCHORS`: a finite map from docname to the doctree id set.
- `FILES`: the finite set of local source-tree file paths known by
  `path.exists`.

Out of scope for the proof: network results, filesystem races after
`prepare_writing`, and full Python/K semantics. Those remain trusted-base or
integration concerns.

## Formal Claims

K-style claims below are specification sketches for the `check()` local branch
and `process_result()` status effect. They are constructed, not machine-checked.

```k
// CLAIM C1: relative missing local target is broken.
// SPEC-PROVENANCE: IE1, IE2
claim <k> checkLocal("doesntexist", DOC) => ("broken", "local file not found") ... </k>
      <localLinks> true </localLinks>
      <docUri> DOCURI </docUri>
      <files> FILES </files>
  requires notBool "doesntexist" in_keys(DOCURI)
   andBool notBool "doesntexist" in_set(FILES)

// CLAIM C2: known local document target is local.
// SPEC-PROVENANCE: IE1, IE3
claim <k> checkLocal(URI, DOC) => ("local", "") ... </k>
      <localLinks> true </localLinks>
      <docUri> URI |-> TARGETDOC DOCURI </docUri>

// CLAIM C3: known source-tree file target is local.
// SPEC-PROVENANCE: IE3
claim <k> checkLocal(URI, DOC) => ("local", "") ... </k>
      <localLinks> true </localLinks>
      <docUri> DOCURI </docUri>
      <files> URI FILES </files>
  requires notBool URI in_keys(DOCURI)

// CLAIM C4: absolute or scheme-qualified local URI remains local.
// SPEC-PROVENANCE: IE4
claim <k> checkLocal(URI, DOC) => ("local", "") ... </k>
      <localLinks> true </localLinks>
  requires isAbsoluteOrScheme(URI)

// CLAIM C5: opt-out preserves local status.
// SPEC-PROVENANCE: IE5
claim <k> checkLocal(URI, DOC) => ("local", "") ... </k>
      <localLinks> false </localLinks>
  requires notBool startsWith(URI, "#")

// CLAIM C6: anchor-only opt-out preserves old unchecked status.
// SPEC-PROVENANCE: IE5, IE8
claim <k> check("#frag", DOC) => ("unchecked", "") ... </k>
      <localLinks> false </localLinks>

// CLAIM C7: missing local document anchor is broken when anchors are enabled.
// SPEC-PROVENANCE: IE6
claim <k> checkLocal("target.html#missing", DOC)
          => ("broken", "Anchor 'missing' not found") ... </k>
      <localLinks> true </localLinks>
      <anchors> true </anchors>
      <docUri> "target.html" |-> TARGETDOC DOCURI </docUri>
      <docAnchors> TARGETDOC |-> IDS DOCANCHORS </docAnchors>
  requires notBool "missing" in_set(IDS)

// CLAIM C8: ignored local anchor is local.
// SPEC-PROVENANCE: IE7
claim <k> checkLocal("target.html#!dynamic", DOC) => ("local", "") ... </k>
      <localLinks> true </localLinks>
      <anchors> true </anchors>
      <anchorsIgnore> "^!" </anchorsIgnore>
      <docUri> "target.html" |-> TARGETDOC DOCURI </docUri>

// CLAIM C9: any broken result sets builder statuscode to 1.
// SPEC-PROVENANCE: IE2, IE8
claim <k> processResult(("broken", INFO), DOC) => .K ... </k>
      <hasBroken> false => true </hasBroken>
      <statuscode> 0 => 1 </statuscode>
```

## Adequacy Audit

- C1 directly covers the reported local-link symptom.
- C2 and C3 encode positive local targets. C3 is a conservative pragmatic
  assumption: source-tree files are visible to Sphinx, but deploy-only files are
  not.
- C4 is required by the public hint about absolute path ambiguity.
- C5 and C6 are required by the optional-feature hint and compatibility with
  pre-existing anchor-only handling when local checking is disabled.
- C7 and C8 are required by the public `linkcheck_anchors` and
  `linkcheck_anchors_ignore` contracts.
- C9 is required because a checked broken local link must make `make linkcheck`
  finish with problems, matching existing broken-link behavior.

No claim relies on hidden tests, upstream fixes, or benchmark outcomes.
