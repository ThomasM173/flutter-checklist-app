// tool/prepare_app_icon.dart — bleed the icon artwork to the canvas edges.
//
// flutter_launcher_icons (and the OS) apply a circular/rounded mask on top
// of assets/icon/app_icon.png at display time. If the actual artwork sits
// in the middle of the 1024x1024 canvas with a lot of white margin around
// it (easy to end up with when exporting straight from a design tool), the
// mask crops mostly into that white margin and the icon looks like a tiny
// logo floating in an empty circle.
//
// This finds the bounding box of all non-near-white content, scales the
// WHOLE image up until that content's shorter dimension slightly exceeds
// the canvas size (intentional bleed off every edge), and re-centers it on
// a fresh white 1024x1024 canvas. Run it whenever the source icon art
// changes, then re-run flutter_launcher_icons:
//
//   dart run tool/prepare_app_icon.dart
//   dart run flutter_launcher_icons
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const srcPath = 'assets/icon/app_icon.png';
  const canvasSize = 1024;
  const fillFactor = 1.06; // how far past the edge the content should bleed

  final bytes = File(srcPath).readAsBytesSync();
  final src = img.decodePng(bytes)!;
  print('source: ${src.width}x${src.height}');

  int minX = src.width, minY = src.height, maxX = 0, maxY = 0;
  bool isNearWhite(img.Pixel p) => p.r > 248 && p.g > 248 && p.b > 248;

  for (int y = 0; y < src.height; y++) {
    for (int x = 0; x < src.width; x++) {
      if (!isNearWhite(src.getPixel(x, y))) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  final bboxW = maxX - minX + 1;
  final bboxH = maxY - minY + 1;
  final cx = minX + bboxW / 2;
  final cy = minY + bboxH / 2;
  print('content bbox: x=$minX..$maxX y=$minY..$maxY (${bboxW}x$bboxH)');

  final scale = (canvasSize / bboxH) * fillFactor;
  print('scale factor: ${scale.toStringAsFixed(3)}');

  final resizedW = (src.width * scale).round();
  final resizedH = (src.height * scale).round();
  final resized = img.copyResize(
    src,
    width: resizedW,
    height: resizedH,
    interpolation: img.Interpolation.cubic,
  );

  // Crop the resized image directly rather than compositing with a
  // (possibly negative) destination offset onto a blank canvas - this
  // library's compositeImage does not clip negative dst coordinates
  // correctly and silently produces a blank result.
  final cropX = (cx * scale - canvasSize / 2).round().clamp(0, resizedW - canvasSize);
  final cropY = (cy * scale - canvasSize / 2).round().clamp(0, resizedH - canvasSize);
  final canvas = img.copyCrop(
    resized,
    x: cropX,
    y: cropY,
    width: canvasSize,
    height: canvasSize,
  );

  File(srcPath).writeAsBytesSync(img.encodePng(canvas));
  print('wrote $srcPath (cropped at $cropX,$cropY from ${resizedW}x$resizedH)');
}
