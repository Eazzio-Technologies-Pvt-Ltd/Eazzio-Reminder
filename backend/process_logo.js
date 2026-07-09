const Jimp = require('jimp');

Jimp.read('C:\\Users\\asus\\.gemini\\antigravity-ide\\brain\\253af99c-1cf0-4d24-83dc-3eb5636aa0a3\\media__1781605742738.png')
  .then(image => {
    const w = image.bitmap.width;
    const h = image.bitmap.height;
    
    // Background color is e2e1f5. We will replace pixels that are close to e2e1f5 with transparent
    // Let's use a tolerance.
    const targetR = 0xe2;
    const targetG = 0xe1;
    const targetB = 0xf5;
    const tolerance = 40; // color distance tolerance
    
    // Make transparent
    for (let y = 0; y < h; y++) {
      for (let x = 0; x < w; x++) {
        const color = image.getPixelColor(x, y);
        const r = (color >> 24) & 0xff;
        const g = (color >> 16) & 0xff;
        const b = (color >> 8) & 0xff;
        const a = color & 0xff;
        
        const dist = Math.sqrt(
          Math.pow(r - targetR, 2) +
          Math.pow(g - targetG, 2) +
          Math.pow(b - targetB, 2)
        );
        
        if (dist < tolerance) {
          image.setPixelColor(0x00000000, x, y); // transparent
        }
      }
    }
    
    // Crop transparent edges
    let minX = w, maxX = 0, minY = h, maxY = 0;
    for (let y = 0; y < h; y++) {
      for (let x = 0; x < w; x++) {
        const color = image.getPixelColor(x, y);
        const a = color & 0xff;
        if (a > 0) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }
    
    console.log('Non-transparent bounding box:', minX, minY, maxX, maxY);
    if (maxX >= minX && maxY >= minY) {
      // Crop with 2px padding
      const cropX = Math.max(0, minX - 2);
      const cropY = Math.max(0, minY - 2);
      const cropW = Math.min(w - cropX, maxX - minX + 5);
      const cropH = Math.min(h - cropY, maxY - minY + 5);
      image.crop(cropX, cropY, cropW, cropH);
      console.log('Cropped dimensions:', image.bitmap.width, 'x', image.bitmap.height);
      image.write('C:\\Users\\asus\\.gemini\\antigravity-ide\\brain\\253af99c-1cf0-4d24-83dc-3eb5636aa0a3\\scratch\\logo_transparent.png');
      console.log('Saved transparent cropped logo to scratch');
    } else {
      console.log('No non-transparent pixels found!');
    }
  })
  .catch(err => console.error(err));
