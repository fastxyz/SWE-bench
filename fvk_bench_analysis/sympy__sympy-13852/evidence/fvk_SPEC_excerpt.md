# Evidence excerpts — fvk/SPEC.md  (sympy__sympy-13852)
Source: results/batch5-XC-MINI-PRO-AHP-260614105258/sympy__sympy-13852/fvk/SPEC.md
Quoted verbatim with SPEC.md line numbers. The spec scopes the WHOLE audit to
`polylog._eval_expand_func` ONLY; it never considers `polylog.eval` (where the gold
fix lives).

## Target / scope (locks audit to the wrong method)
- SPEC.md:1   `# SPEC — \`polylog._eval_expand_func\` (sympy__sympy-13852)`
- SPEC.md:3   `**Target file:** \`repo/sympy/functions/special/zeta_functions.py\``
- SPEC.md:4   `**Target function:** \`polylog._eval_expand_func(self, **hints)\``
- SPEC.md:9-11 "This function is a pure, side-effect-free **dispatch** that rewrites a
  symbolic `polylog(s, z)` node into a more elementary closed form when one is known,
  and otherwise returns the node unchanged."

## polylog expansion identity polylog(1,z) = -log(1-z)  (L3, L5)
- SPEC.md:21 (L3) `"\`polylog(1, z)\` and \`-log(1-z)\` are exactly the same function for all purposes ... both return the same values [over thousands of points]" | \`expand_func(polylog(1, z)) = -log(1 - z)\` (no \`exp_polar\`) | **must hold** (V1 target)`
- SPEC.md:44 (postcondition) `E(s, z) ==  -log(1 - z)                 if s == 1`
- SPEC.md:99 (K rule B1) `rule <k> expand(1, _Z) => . ... </k> <out> _ => neglog1mz </out>`
- SPEC.md:82  `syntax Expr ::= "neglog1mz"             // -log(1 - z)`
- SPEC.md:144 (claim EXPAND-S1) `claim <k> expand(1, Z:ZVal) => . </k> <out> _ => neglog1mz </out>   [all-path]`
- SPEC.md:213-216 plain-English: "`s = 1` → `-log(1 - z)`. ... there is deliberately
  **no** `exp_polar` factor (it would encode a winding number about `z = 1`, where
  `log` is not branched ...)."

## special value polylog(2, 1/2)  (L1, L2)  -- ONLY this one value
- SPEC.md:19 (L1) `"\`polylog(2, Rational(1,2)).expand(func=True)\` ... The answer should be \`-log(2)**2/2 + pi**2/12\`" | \`expand_func(polylog(2, 1/2)) = pi**2/12 - log(2)**2/2\` | **must hold** (V1 target)`
- SPEC.md:45 (postcondition) `        ==  pi**2/12 - log(2)**2/2       if s == 2  and  z == S.Half`
- SPEC.md:101-102 (K rule B2) `// Branch 2 : if s == 2 and z == 1/2: return Li_2(1/2) closed form` /
  `rule <k> expand(2, half) => . ... </k> <out> _ => dilogHalf </out>`
- SPEC.md:150 (claim EXPAND-HALF) `claim <k> expand(2, half) => . </k> <out> _ => dilogHalf </out>    [all-path]`
- SPEC.md:217-218 plain-English: "`s = 2`, `z = 1/2` → `pi**2/12 - log(2)**2/2`, the
  classical value of the dilogarithm `Li_2(1/2) ≈ 0.582240526`."

## NOTE: s==2 with z != 1/2 is EXPLICITLY frozen to "no-op" (this is the bug)
- SPEC.md:46-47 (postcondition) the only non-no-op s>=2 case is z==1/2; everything
  else: `        ==  polylog(s, z)                otherwise   (incl. symbolic s, non-1/2 z)`
- SPEC.md:111 (K rule B4) `rule <k> expand(2, zoth) => . ... </k> <out> _ => polylogNode </out>`
- SPEC.md:157-158 (claim EXPAND-FRAME-2) `// s == 2 with z != 1/2 must NOT collapse to the special value.` /
  `claim <k> expand(2, zoth) => . </k> <out> _ => polylogNode </out>  [all-path]`
  >>> TELL (c): this postcondition CERTIFIES the buggy narrowness. Gold REQUIRES
  s==2 to also evaluate at z=2 and at four golden-ratio args; spec declares those
  must stay polylog(2,z) unchanged. Spec diverges from documented math intent.
- SPEC.md:220-221 "anything else (symbolic `s`, or `s = 2` with `z ≠ 1/2`, or
  `s ≥ 3`) → `polylog(s, z)` unchanged."

## eval is mentioned ONLY as a guard that REMOVES z in {0,1,-1} -- never as the
## place to ADD special values (the actual gold fix site)
- SPEC.md:28 (L10) `\`polylog(s, 1) -> zeta(s)\`, \`polylog(s, -1) -> -dirichlet_eta(s)\`, \`polylog(s, 0) -> 0\` handled in \`eval\` *before* expand | \`eval\` short-circuits \`z∈{0,1,-1}\`, so \`_eval_expand_func\` only ever sees \`z∉{0,1,-1}\` ...`
- SPEC.md:38-39 "By L10, `eval` has already removed `z ∈ {0, 1, -1}` (those never
  reach this method via the public API)."
  >>> This is the closest the spec comes to polylog.eval. It treats eval purely as a
  pre-filter for singular z, and never asks whether the NEW special values belong in
  eval (they do, in gold). The construction-time `polylog(2, S.Half) == ...` form the
  gold test asserts is never specified.

## derivative consistency expand_func commutes with d/dz  (L4)
- SPEC.md:22 (L4) `\`expand_func(diff(polylog(1,z) + log(1-z), z))\` should be \`0\`; current code "changes the derivative" | \`expand_func\` must commute with \`d/dz\` ...`
- SPEC.md:50-55 "Universal correctness invariant ... E(s, z) is *analytically equal*
  to `polylog(s, z)` ... with consistent branch cuts. ... This is the property that
  makes `expand_func` commute with `diff` (L4)."
- SPEC.md:199-204 VC-Frame: "`polylog`'s `fdiff` is unchanged ... ⇒ `expand_func`
  commutes with `diff` (closes L4)."

## branch cuts / exp_polar
- SPEC.md:23 (L5) `"exp_polar ... winding number about 1 ... irrelevant because log is not branched at 1" | the removed \`exp_polar(-I*pi)\` factor carried no analytic content`
- SPEC.md:192-194 VC-Li1: "`neglog1mz ≡ polylog(1, z)` as SymPy functions, including
  branch cuts (for real `z>1`, both have imaginary part `-pi`)."

## derivative fdiff identity
- SPEC.md:204 `\`d/dz E = E(s-1)/z\` holds wherever \`polylog\`'s does`
  (this is polylog(s,z).diff(z) = polylog(s-1,z)/z, the fdiff identity, treated as
  UNCHANGED and out of scope).
