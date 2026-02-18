// Minimal stub for image_cropper plugin API used by the app.
// This is a pure-Dart implementation that just returns the original file path.

class CroppedFile {
  final String path;
  CroppedFile(this.path);
}

enum CropAspectRatioPreset { square, original }

class AndroidUiSettings {
  final String toolbarTitle;
  final Object? toolbarColor;
  final Object? toolbarWidgetColor;
  final CropAspectRatioPreset initAspectRatio;
  final bool lockAspectRatio;
  final List<CropAspectRatioPreset>? aspectRatioPresets;

  AndroidUiSettings({
    required this.toolbarTitle,
    this.toolbarColor,
    this.toolbarWidgetColor,
    this.initAspectRatio = CropAspectRatioPreset.square,
    this.lockAspectRatio = false,
    this.aspectRatioPresets,
  });
}

class IOSUiSettings {
  final String title;
  final List<CropAspectRatioPreset>? aspectRatioPresets;
  IOSUiSettings({required this.title, this.aspectRatioPresets});
}

class WebUiSettings {
  final Object? context;
  WebUiSettings({this.context});
}

class ImageCropper {
  Future<CroppedFile?> cropImage(
      {required String sourcePath, List<dynamic>? uiSettings}) async {
    // Quick stub: return original file as "cropped" file.
    return CroppedFile(sourcePath);
  }
}
