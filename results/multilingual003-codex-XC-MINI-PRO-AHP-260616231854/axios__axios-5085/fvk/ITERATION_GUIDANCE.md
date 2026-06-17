# FVK Iteration Guidance

Status: constructed, not machine-checked.

## V2 Code Changes Applied

G-001: Patch minified runtime mirrors.

Reason: Finding F-001 showed V1 left `repo/dist/axios.min.js` and `repo/dist/esm/axios.min.js` with scalar-only normalizers. This violated proof obligation O-005.

Applied change:

- `repo/dist/axios.min.js`: array values now return `e.map(ue)`.
- `repo/dist/esm/axios.min.js`: array values now return `e.map(re)`.

## V1 Code Kept

G-002: Keep the source-level V1 fix in `repo/lib/core/AxiosHeaders.js`.

Reason: Finding F-004 and proof obligations O-001 through O-004 confirm the source fix satisfies the main issue contract.

G-003: Keep non-minified distribution V1 edits.

Reason: They are required by O-005 and already match the source behavior.

G-004: Keep `toJSON()` unchanged.

Reason: Finding F-002 and O-006 show changing `toJSON()` would be a broader serialization change not required by `get('set-cookie')`.

## Follow-Up If Build Execution Is Allowed Later

G-005: Regenerate distribution artifacts and source maps with the repository's normal build.

Reason: Finding F-003 records that source maps may be stale after manual no-execution edits. This does not block the runtime fix, but it should be handled before a release outside the benchmark constraints.

G-006: Add or keep tests around:

- `AxiosHeaders.from({ 'set-cookie': ['a', 'b'] }).normalize().get('set-cookie')`.
- raw header parsing with repeated `Set-Cookie` lines followed by `normalize()` and `get('set-cookie')`.
- Node adapter response handling for `res.headers['set-cookie']` arrays.

No tests were edited in this task.
