# Baseline Notes

## Root cause

`SegmentInfos.replace(SegmentInfos other)` replaced the segment list and copied `lastGeneration` from
the replacement `SegmentInfos`, but it left the current instance's `userData` unchanged. When an
`IndexWriter` is initialized from an explicit older `IndexCommit`, the writer reads that commit into
a temporary `SegmentInfos` and calls `segmentInfos.replace(oldInfos)`. Because `userData` was not
copied, the writer could keep commit user data from the latest commit while using the segments from
the requested commit.

## Changed files

`repo/lucene/core/src/java/org/apache/lucene/index/SegmentInfos.java`

Copied `other.userData` in `replace` so the commit metadata follows the replacement commit state.
This keeps `replace` consistent with its role of swapping in another commit's segment state while
still preserving the write-once generation/version/counter behavior documented by the method.

## Assumptions and alternatives considered

I treated `userData` as part of the commit state that must be restored with the replacement
`SegmentInfos`, not as writer-local metadata that should survive a replace. This matches the issue
description and the nearby `IndexWriter` initialization path that calls `replace` for a selected
commit.

I considered defensively copying the map with `new HashMap<>(other.userData)`, but rejected it as a
larger behavioral change. The existing `setUserData` method stores the provided map directly, and
`replace` already reuses the replacement segment objects through `other.asList()` rather than
deep-copying the entire state. Direct assignment is therefore the minimal fix for the reported
metadata omission.
