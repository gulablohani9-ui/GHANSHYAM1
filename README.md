# Vastu Plot + Chakra PDF App

This version fixes Android CHKRA folder reading by using Android's Storage Access Framework (SAF) directly.

## Main features

- Plot photo selection
- Unlimited draggable boundary points
- Plot/North degree
- **Real Android folder selection for CHKRA**
- Reads PNG/JPG/JPEG/WebP images from the selected CHKRA folder, including images inside subfolders
- Keeps access to the selected folder for Refresh after the first selection
- Shows the detected Chakra filenames in the app
- Chakra overlays directly on top of the plot photo
- Finger move, pinch zoom and rotate
- Slider and +/- degree controls
- Plot degree automatically sets the Chakra rotation when the degree is changed
- PDF: 1 client/plot page + one overlaid plot page per Chakra
- Footer: Ghanshyam Lohani

## Important CHKRA workflow

1. Create a folder named **CHKRA** in phone storage.
2. Put PNG/JPG/JPEG/WebP Chakra images inside it.
3. In the app tap **CHKRA Folder Select करें**.
4. Select the actual **CHKRA** folder and press **Use this folder** if Android shows that button.
5. The app reads the images through Android's folder permission. It does not depend on `dart:io Directory.list()` for the selected Android folder.
6. After adding more images to CHKRA, press **Refresh CHKRA Folder**.

## GitHub build

Push this project to GitHub and run **Actions → Build Android APK**. The workflow creates the Android project, installs the native CHKRA reader, runs `flutter analyze`, and builds the release APK.

The generated stale `test/widget_test.dart` is removed before analysis.
