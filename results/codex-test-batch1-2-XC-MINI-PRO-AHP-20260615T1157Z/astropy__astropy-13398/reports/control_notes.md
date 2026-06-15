# Control Notes

The control review found no source defect requiring a V2 code change, so the V1
fix stands unchanged.

Finding 1 confirms that the direct ITRS to AltAz/HADec transforms implement the
issue's requested topocentric treatment for nearby Earth-fixed positions.
Finding 2 confirms that the inverse observed to ITRS path is consistent with the
new topocentric ITRS origin model. Finding 3 checks the refraction path and the
`obstime` boundary: refraction still uses the existing CIRS-observed machinery
when time is available, while the no-refraction direct rotation can operate
without time. Finding 4 confirms that adding `location` to ITRS preserves the
default geocentric API while allowing explicit topocentric origins, and that the
new ITRS self-transform correctly avoids the old inertial loop. Finding 5 checks
that CIRS/TETE interactions normalize through geocentric ITRS before applying
the existing rotation matrices. Finding 6 covers missing locations and
unit-spherical or dimensionless data. Finding 7 checks graph registration and
`earth_location` compatibility.

Because these findings did not identify a blocking issue, I made no additional
source edits. The only control-pass outputs are `review/FINDINGS.md` and this
decision record.
