# Asset Notebook VPM validation

The canonical listing remains https://horicraft.github.io/asset-catalog-vpm/index.json. A second website at https://horicraft.github.io/asset-notebook-vpm/ uses the same addRepo target. Do not change the canonical URL or listing ID as a side effect of a display-name change.

## Transition checks

1. Preserve every historical version object and ZIP byte-for-byte. Compare the package ID, listing ID, canonical URL, version set and all three ZIP SHA-256 values against the reviewed baseline.
2. Generate the old compatibility site and new-name site from one reviewed snapshot, rather than editing listings independently. Deploy both with their own existing Pages workflow; no cross-repository token or private source is needed.
3. Do not use HTML/JavaScript redirects for index.json or package downloads. Both paths must return valid JSON/ZIP directly.
4. Fetch both listings and all historical package URLs anonymously after deployment. Compare SHA values and listing contents, then check existing-repository updates in isolated VCC / ALCOM profiles. Product acceptance is separate from deployment checks.
5. Do not advertise a new feed registration URL before duplicate-ID/canonical-URL behavior is verified in both clients. Current add buttons continue using the established listing URL.

## Package staging

`tools/prepare-listing.ps1` validates the package manifest, version, checksum, paid license marker and DLL-only ZIP allowlist before writing a new output directory. Source C#, activation-key HTML, databases, images and validation code are rejected.

`LocalTest` requires a loopback HTTP URL. `Publish` staging still accepts only `https://horicraft.github.io/asset-catalog-vpm/` and a release-eligible build report. These modes prepare files only; they never push or deploy. The generated one-version staging listing must be merged with the reviewed historical versions before publication. Never replace the full feed with a single-version staging output.

The new-name snapshot contains only public distribution files from the reviewed public repository. Keep candidate ZIPs immutable. Do not publish the in-development next binary as part of this branding transition.

Future releases must keep the two listing snapshots in sync. Upload and verify required ZIPs before changing feeds; do not announce a release until both sites pass the publication checks. Stop if either compatibility endpoint is unavailable or stale.
