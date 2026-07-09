import 'dart:io';
import 'package:image/image.dart' as img;

img.Image makeTransparent(img.Image src, img.Pixel bg, {int tolerance = 30}) {
  final result = src.numChannels == 4 ? src : src.convert(numChannels: 4);
  
  final bgR = bg.r;
  final bgG = bg.g;
  final bgB = bg.b;
  
  for (final frame in result.frames) {
    for (final pixel in frame) {
      final pr = pixel.r;
      final pg = pixel.g;
      final pb = pixel.b;
      
      final diffR = (pr - bgR).abs();
      final diffG = (pg - bgG).abs();
      final diffB = (pb - bgB).abs();
      
      if (diffR <= tolerance && diffG <= tolerance && diffB <= tolerance) {
        pixel.a = 0;
      }
    }
  }
  return result;
}

img.Image cropContent(img.Image src, {int padding = 5}) {
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
  
  // Add padding
  minX = (minX - padding).clamp(0, src.width);
  minY = (minY - padding).clamp(0, src.height);
  maxX = (maxX + padding).clamp(0, src.width);
  maxY = (maxY + padding).clamp(0, src.height);
  
  final width = maxX - minX;
  final height = maxY - minY;
  if (width <= 0 || height <= 0) return src;
  
  return img.copyCrop(src, x: minX, y: minY, width: width, height: height);
}

void main() {
  final sourcePath = r"C:\Users\asus\.gemini\antigravity-ide\brain\195497f5-159f-486a-a73a-294c130a7320\media__1781627568197.jpg";
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
  
  final w = image.width;
  final h = image.height;
  print("Loaded image size: ${w}x${h}");
  
  // Crop top half (Light Mode Logo)
  final topHalf = img.copyCrop(image, x: 0, y: 0, width: w, height: h ~/ 2);
  // Crop bottom half (Dark Mode Logo)
  final bottomHalf = img.copyCrop(image, x: 0, y: h ~/ 2, width: w, height: h - (h ~/ 2));
  
  // Get background pixel from each half
  final lightBg = topHalf.getPixel(5, 5);
  print("Light bg BGR values: R=${lightBg.r}, G=${lightBg.g}, B=${lightBg.b}");
  final logoLight = makeTransparent(topHalf, lightBg, tolerance: 30);
  
  final darkBg = bottomHalf.getPixel(5, 5);
  print("Dark bg BGR values: R=${darkBg.r}, G=${darkBg.g}, B=${darkBg.b}");
  final logoDark = makeTransparent(bottomHalf, darkBg, tolerance: 25);
  
  // Crop tightly
  final logoLightCropped = cropContent(logoLight);
  final logoDarkCropped = cropContent(logoDark);
  
  // Save files
  final lightOut = r"c:\Users\asus\OneDrive\Desktop\eazzio-reminder\frontend\assets\images\logo_light.png";
  final darkOut = r"c:\Users\asus\OneDrive\Desktop\eazzio-reminder\frontend\assets\images\logo_dark.png";
  
  File(lightOut).writeAsBytesSync(img.encodePng(logoLightCropped));
  File(darkOut).writeAsBytesSync(img.encodePng(logoDarkCropped));
  
  print("Saved light logo to: $lightOut");
  print("Saved dark logo to: $darkOut");
}
