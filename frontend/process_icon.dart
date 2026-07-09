import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  final sourcePath = r"C:\Users\asus\.gemini\antigravity-ide\brain\548bad42-85ff-473c-ac72-f62cf8d496af\media__1781690554286.jpg";
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
  
  // Find bounding box of blue pixels
  int minX = w;
  int maxX = 0;
  int minY = h;
  int maxY = 0;
  bool foundBlue = false;
  
  // Scan all pixels to find the blue circle boundaries
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final pixel = image.getPixel(x, y);
      final r = pixel.r;
      final g = pixel.g;
      final b = pixel.b;
      
      // Blue color check: blue channel is higher than red and green by a margin
      if (b > r + 30 && b > g + 20) {
        foundBlue = true;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  
  if (!foundBlue) {
    print("Could not detect the blue circle in the image!");
    return;
  }
  
  print("Blue circle bounding box: minX=$minX, maxX=$maxX, minY=$minY, maxY=$maxY");
  
  int circleW = maxX - minX;
  int circleH = maxY - minY;
  
  // We want a square bounding box centered around the circle
  int size = max(circleW, circleH);
  int centerX = minX + circleW ~/ 2;
  int centerY = minY + circleH ~/ 2;
  
  // New bounding box coordinates
  int newMinX = centerX - size ~/ 2;
  int newMinY = centerY - size ~/ 2;
  
  // Ensure it fits within image bounds
  newMinX = newMinX.clamp(0, w - size);
  newMinY = newMinY.clamp(0, h - size);
  
  // Crop the square containing the circle
  final cropped = img.copyCrop(image, x: newMinX, y: newMinY, width: size, height: size);
  
  // Convert to 4 channels for transparency
  final result = cropped.numChannels == 4 ? cropped : cropped.convert(numChannels: 4);
  
  // Apply a circular mask to make everything outside the circle transparent
  double rMask = (size / 2.0) - 1.5; // Slightly smaller to avoid anti-aliasing artifacts
  double centerMask = size / 2.0;
  
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final dx = x + 0.5 - centerMask;
      final dy = y + 0.5 - centerMask;
      final dist = sqrt(dx * dx + dy * dy);
      
      if (dist > rMask) {
        final pixel = result.getPixel(x, y);
        pixel.a = 0; // Set transparency
      }
    }
  }
  
  // Save as app_logo.png
  final outPath = r"c:\Users\asus\OneDrive\Desktop\eazzio-reminder\frontend\assets\images\app_logo.png";
  File(outPath).writeAsBytesSync(img.encodePng(result));
  print("Successfully saved cropped circle logo to: $outPath");
}
