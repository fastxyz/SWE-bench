# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, tests,
Python, or project code were run.

## What is proved

For the in-domain `--jobs=0` CPU auto-detection path:

1. The cgroup shares calculation returns `max(1, int(cpu_shares / 1024))`, so a
   positive share value below `1024` returns `1` rather than `0`.
2. The cgroup quota calculation returns `max(1, int(cpu_quota / cpu_period))`
   for positive quota and positive period, so a positive fractional quota below
   one full CPU returns `1` rather than `0`.
3. `_cpu_count()` returns a positive value when the host/scheduler count is at
   least `1`, both when cgroup data exists and when it is absent.
4. The `jobs == 0` branch assigns a positive worker count before linting reaches
   multiprocessing.

## Proof sketch

The K model in `mini-python-cpu.k` defines these total helper functions over the
verified domain:

- `max1Int(N) = N` when `N >= 1`, otherwise `1`.
- `minCpuInt(A, B) = A` when `A <= B`, otherwise `B`.
- `queryShares(S) = max1Int(S /Int 1024)` for `S > 0`.
- `queryQuota(Q, P) = max1Int(Q /Int P)` for `Q > 0` and `P > 0`.
- `cpuCountSome(S, H) = max1Int(minCpuInt(S, H))` for `H >= 1`.
- `cpuCountNone(H) = H` for `H >= 1`.

For `QUERY-SHARES-POSITIVE`, symbolic execution rewrites
`queryShares(SHARES)` to `max1Int(SHARES /Int 1024)`. Case analysis on
`SHARES /Int 1024 >= 1` proves either the quotient is already positive or the
clamp returns `1`. Both branches satisfy `RESULT >= 1`.

For `QUERY-SHARES-REPORTED`, substitution with `SHARES = 2` gives
`2 /Int 1024 = 0`, then `max1Int(0) = 1`.

For `QUERY-QUOTA-POSITIVE`, the proof is the same as the shares proof after
substituting `Q /Int P` for the quotient. For the fractional subclaim
`0 < Q < P`, integer truncation gives `Q /Int P = 0`, and `max1Int(0) = 1`.

For `CPU-COUNT-SOME-POSITIVE`, symbolic execution rewrites to
`max1Int(minCpuInt(SHARE, HOST))`. Regardless of whether `SHARE <= HOST`, the
inner `minCpuInt` returns an integer and the outer `max1Int` enforces a lower
bound of `1`. The defensive point claim with `SHARE = 0` and `HOST >= 1`
therefore returns `1`.

For `CPU-COUNT-NONE-PRESERVES`, the model rewrites directly to `HOST`; the
precondition `HOST >= 1` discharges both preservation and positivity.

For `AUTO-JOBS-WITH-MP`, the model assumes the already-proved `_cpu_count()`
result `CPU >= 1` and rewrites the job assignment to `CPU`. For
`AUTO-JOBS-NO-MP`, the model rewrites directly to `1`.

There are no loops or recursion in the audited fragment, so no circularity claim
is required.

## Machine-check commands

These commands are part of the artifact contract. They were not executed here.

```sh
cd fvk
kompile mini-python-cpu.k --backend haskell
kast --backend haskell pylint-cpu-spec.k
kprove pylint-cpu-spec.k
```

Expected result after a successful machine check: `kprove` returns `#Top`.

## Residual risk

The proof is partial correctness over the modeled arithmetic and branch
fragment. It does not prove filesystem availability, parsing behavior for
malformed cgroup files, operating-system guarantees about cgroup file values, or
performance. It relies on the mini-K semantics faithfully modeling the relevant
Python operations: `int(a / b)` for positive integers as truncating integer
division, `max`, `min`, and the `jobs == 0` branch.

## Test guidance

Do not remove any tests from this benchmark. If the K proof is later
machine-checked, focused unit tests that only assert the in-domain arithmetic
cases above are logically subsumed by the proof, but integration tests covering
actual filesystem/cgroup wiring and multiprocessing should be kept.
