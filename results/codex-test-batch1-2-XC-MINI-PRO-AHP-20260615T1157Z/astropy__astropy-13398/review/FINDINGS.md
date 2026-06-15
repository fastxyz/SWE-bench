# Control Review Findings

1. **Correctness against the issue:** V1 addresses the core issue by adding direct
   ITRS to observed-frame transforms and avoiding the old path through inertial
   apparent coordinates for the default no-refraction case. The transform first
   forms a topocentric ITRS vector by subtracting the observer's ITRS location,
   then applies the local ITRS-to-AltAz or ITRS-to-HADec rotation. That matches
   the issue's requested behavior for nearby Earth-fixed positions such as
   satellites and avoids the geocentric/topocentric aberration confusion that
   motivated the report.

2. **Observed-frame inverse behavior:** The observed to ITRS path applies the
   inverse local rotation and realizes the result as an ITRS coordinate whose
   `location` is the observer. Transforming that intermediate coordinate to the
   requested output ITRS frame delegates origin shifts to the ITRS self-transform.
   This is consistent with the new topocentric ITRS model and preserves round-trip
   behavior conceptually without needing a separate special case for geocentric
   output frames.

3. **Refraction and `obstime` handling:** V1 keeps refraction-corrected observed
   transforms on the existing CIRS-observed machinery after first converting the
   ITRS vector to topocentric CIRS at the observed frame's `obstime`. It raises
   when refraction is requested without an `obstime`, which is necessary because
   the ERFA observed-frame astrometry context cannot be formed without time. For
   the no-refraction path, allowing `obstime=None` is reasonable because the local
   ITRS-to-observed rotation depends only on the observer's geodetic longitude and
   latitude.

4. **ITRS frame-origin semantics:** Adding an `EarthLocation` `location` attribute
   to ITRS defaults to `EARTH_CENTER`, so existing geocentric ITRS construction
   remains the default. The new ITRS self-transform shifts only between source and
   target ITRS origins and intentionally does not route through CIRS or another
   inertial frame. That is the necessary behavior for topocentric ITRS offsets and
   directly addresses the issue's complaint that ITRS-to-ITRS changes in `obstime`
   can otherwise move nearby Earth-fixed coordinates by Earth's orbital motion.

5. **Interactions with surrounding intermediate transforms:** The CIRS/TETE to
   ITRS transforms now realize a geocentric ITRS coordinate and then transform to
   the requested ITRS frame, while ITRS to CIRS/TETE first normalizes the input to
   geocentric ITRS. This keeps the existing rotation matrices geocentric and
   isolates topocentric-origin handling in one place. The structure is consistent
   with the existing nearby TETE/CIRS location handling and avoids duplicating
   origin arithmetic in every intermediate transform.

6. **Boundary cases:** V1 explicitly rejects observed-frame transforms without an
   observer location, which is required for topocentric interpretation. It leaves
   unit-spherical or dimensionless Cartesian data as directions and skips origin
   shifts, matching the surrounding observed-frame convention that coordinates
   without a physical distance cannot receive a parallax-style translation. This
   is a defensible boundary choice and does not hide a concrete source defect in
   the current fix.

7. **Registration and API compatibility:** Importing the new
   `itrs_observed_transforms` module from `builtin_frames/__init__.py` registers
   the graph edges. The default ITRS location preserves existing API behavior for
   callers that do not pass `location`, and `earth_location` now adds the frame
   origin before building an `EarthLocation`, so topocentric ITRS data reports the
   correct geocentric Earth location.

8. **Control conclusion:** I found no blocking correctness, error-handling,
   surrounding-transform, or API-contract defect that requires changing V1. The
   baseline source changes should stand unchanged.
