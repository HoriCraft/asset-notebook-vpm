# アセットノート / Asset Notebook VPM

VPM distribution for Asset Notebook by HoriCraft, formerly HoriCraft Asset Catalog.

This public repository contains compiled packages, public distribution metadata and the landing page only. Product source, unlock keys, buyer-only files, databases, purchased assets and private records must never be committed here.

## URLs and compatibility

- New product website: https://horicraft.github.io/asset-notebook-vpm/
- Canonical VCC / ALCOM listing: https://horicraft.github.io/asset-catalog-vpm/index.json
- The previous repository remains an active compatibility distribution endpoint. Existing users do not need to remove or re-add it.
- Listing ID remains `com.horicraft.asset-catalog.vpm`; package ID remains `com.horicraft.booth-library-unity`.
- Both distribution sites must serve the same listing snapshot. The canonical listing URL and historical ZIP URLs stay unchanged. Do not rely on a GitHub repository redirect to redirect a Pages URL.

candidate.3 / .4 / .5 are immutable historical packages with the previous display name. This transition changes the listing/website branding only and does not publish a new binary. The currently released candidate.5 still opens from `HoriCraft > Asset Catalog` in Unity. A reviewed future package will carry the new Unity display name.

Product functions require an activation key. Prerelease availability does not indicate that BOOTH sales have started.

Validation and publication staging: [TESTING.md](TESTING.md).
