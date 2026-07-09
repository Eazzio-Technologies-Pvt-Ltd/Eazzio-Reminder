import 'dart:io';
import 'package:image/image.dart' as img;

img.Image makeTransparent(img.Image src, {int tolerance = 30}) {
  final result = src.numChannels == 4 ? src : src.convert(numChannels: 4);
  
  for (final frame in result.frames) {
    for (final pixel in frame) {
      final pr = pixel.r;
      final pg = pixel.g;
      final pb = pixel.b;
      
      final diffR = (pr - 255).abs();
      final diffG = (pg - 255).abs();
      final diffB = (pb - 255).abs();
      
      if (diffR <= tolerance && diffG <= tolerance && diffB <= tolerance) {
        pixel.a = 0;
      }
    }
  }
  return result;
}

img.Image cropContent(img.Image src, {int padding = 15}) {
  int minX = src.width;
  int maxX = 0;
  int minY = src.height;
  int maxY = 0;
  bool found = false;
  
  for (final pixel in src) {
    if (pixel.a > 0) {
      found = true;
      if (pixel.x < minX) minX = pixel.x;
      if (pixel.x > maxX) maxX = pixel.x;
      if (pixel.y < minY) minY = pixel.y;
      if (pixel.y > maxY) maxY = pixel.y;
    }
  }
  
  if (!found) {
    return src;
  }
  
  minX = (minX - padding).clamp(0, src.width);
  minY = (minY - padding).clamp(0, src.height);
  maxX = (maxX + padding).clamp(0, src.width);
  maxY = (maxY + padding).clamp(0, src.height);
  
  final width = maxX - minX;
  final height = maxY - minY;
  if (width <= 0 || height <= 0) return src;
  
  return img.copyCrop(src, x: minX, y: minY, width: width, height: height);
}

img.Image makeSquare(img.Image src) {
  final size = src.width > src.height ? src.width : src.height;
  final square = img.Image(width: size, height: size, numChannels: 4);
  
  // Initialize as completely transparent
  for (final pixel in square) {
    pixel.r = 255;
    pixel.g = 255;
    pixel.b = 255;
    pixel.a = 0;
  }
  
  final offsetX = (size - src.width) ~/ 2;
  final offsetY = (size - src.height) ~/ 2;
  
  img.compositeImage(square, src, dstX: offsetX, dstY: offsetY);
  return square;
}

void main() {
  final sourcePath = r"C:\Users\asus\.gemini\antigravity-ide\brain\79678991-0e38-4feb-9af1-4f4709d5c9e9\media__1781696180074.jpg";
  final file = File(sourcePath);
  if (!file.existsSync()) {
    print("Source image not found at $sourcePath");
    return;
  }
  
  final bytes = file.readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) {
    print("Failed to decode image");
    return;
  }
  
  print("Loaded image size: ${image.width}x${image.height}");
  
  // Step 1: Make white transparent
  final transparent = makeTransparent(image, tolerance: 15);
  
  // Step 2: Crop tightly to content
  final cropped = cropContent(transparent, padding: 10);
  
  // Step 3: Center in a square frame for launcher icon
  final squareLogo = makeSquare(cropped);
  
  // Target output paths
  final appLogoOut = r"c:\Users\asus\OneDrive\Desktop\eazzio-reminder\frontend\assets\images\app_logo.png";
  final logoLightOut = r"c:\Users\asus\OneDrive\Desktop\eazzio-reminder\frontend\assets\images\logo_light.png";
  final logoDarkOut = r"c:\Users\asus\OneDrive\Desktop\eazzio-reminder\frontend\assets\images\logo_dark.png";
  
  // Write files
  File(appLogoOut).writeAsBytesSync(img.encodePng(squareLogo));
  File(logoLightOut).writeAsBytesSync(img.encodePng(squareLogo));
  File(logoDarkOut).writeAsBytesSync(img.encodePng(squareLogo));
  
  print("Successfully saved processed logo assets:");
  print(" - $appLogoOut");
  print(" - $logoLightOut");
  print(" - $logoDarkOut");
}
