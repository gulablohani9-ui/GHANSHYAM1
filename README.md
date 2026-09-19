# Vastu Plot + Chakra — Professional V2

This version fixes the PDF/app mismatch by rendering each PDF Chakra page from the same normalized plot-image composition used by the mobile preview.

## Important fixes
- Chakra size, position, rotation and opacity are stored in normalized plot-image coordinates.
- PDF uses the same transform values as the mobile preview; no fixed 360px Chakra size.
- Chakra starts at the geometric centroid of the user-drawn polygon when the Chakra is loaded.
- Plot boundary points are normalized to the plot image.
- Boundary editing has separate **Add Dot**, **Move / Edit**, and **Delete Dot** modes, so touching an existing dot does not create another dot.
- Pinch zoom, two-finger rotation and one-finger movement are supported for Chakra.
- PDF pages are flattened from a rendered composition so the PDF matches the preview much more closely.
- Chakra opacity control is included.
- CHKRA folder is read through Android Storage Access Framework.

## Build
Use GitHub Actions: **Actions → Build Android APK → Run workflow**.

### Analyzer fix V4
This version removes the stale `_polygonCenter` helper and fixes the `Canvas.drawColor` call to provide its required `BlendMode` argument. The GitHub workflow runs `flutter analyze --no-fatal-infos`, so informational lints do not block the APK build; real analyzer errors still fail the build.
