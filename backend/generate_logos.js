const Jimp = require('jimp');
const path = require('path');

const srcPath = 'C:\\Users\\asus\\.gemini\\antigravity-ide\\brain\\253af99c-1cf0-4d24-83dc-3eb5636aa0a3\\media__1781605742738.png';
const destLight = 'c:\\Users\\asus\\OneDrive\\Desktop\\eazzio-reminder\\frontend\\assets\\images\\logo_light.png';
const destDark = 'c:\\Users\\asus\\OneDrive\\Desktop\\eazzio-reminder\\frontend\\assets\\images\\logo_dark.png';

Jimp.read(srcPath)
  .then(async (image) => {
    const w = image.bitmap.width;
    const h = image.bitmap.height;
    
    // Background color is e2e1f5. We will make it transparent
    const targetR = 0xe2;
    const targetG = 0xe1;
    const targetB = 0xf5;
    const tolerance = 45; // color distance tolerance
    
    // We'll process both light and dark logos
    const lightImg = image.clone();
    const darkImg = image.clone();
    
    for (let y = 0; y < h; y++) {
      for (let x = 0; x < w; x++) {
        // Light logo: make background transparent
        const color = lightImg.getPixelColor(x, y);
        const r = (color >> 24) & 0xff;
        const g = (color >> 16) & 0xff;
        const b = (color >> 8) & 0xff;
        
        const dist = Math.sqrt(
          Math.pow(r - targetR, 2) +
          Math.pow(g - targetG, 2) +
          Math.pow(b - targetB, 2)
        );
        
        if (dist < tolerance) {
          lightImg.setPixelColor(0x00000000, x, y);
          darkImg.setPixelColor(0x00000000, x, y);
        } else {
          // Dark logo: convert navy/dark text to white, keep green/teal
          // A pixel is green/teal if g is significantly greater than r and g > b - 20 (to include cyan-ish/teal)
          const isGreenTeal = (g > r + 25) && (g > b - 30);
          
          if (!isGreenTeal) {
            // Navy/dark/other pixel -> convert to white, keeping original alpha
            const alpha = color & 0xff;
            // White with original alpha (using >>> 0 to ensure it is an unsigned 32-bit integer)
            const whiteColor = (((0xff << 24) | (0xff << 16) | (0xff << 8) | alpha) >>> 0);
            darkImg.setPixelColor(whiteColor, x, y);
          }
        }
      }
    }
    
    // Crop both images to the bounding box of non-transparent pixels
    let minX = w, maxX = 0, minY = h, maxY = 0;
    for (let y = 0; y < h; y++) {
      for (let x = 0; x < w; x++) {
        const color = lightImg.getPixelColor(x, y);
        const a = color & 0xff;
        if (a > 10) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }
    
    console.log('Bounding Box:', minX, minY, maxX, maxY);
    if (maxX >= minX && maxY >= minY) {
      const cropX = Math.max(0, minX - 1);
      const cropY = Math.max(0, minY - 1);
      const cropW = Math.min(w - cropX, maxX - minX + 3);
      const cropH = Math.min(h - cropY, maxY - minY + 3);
      
      lightImg.crop(cropX, cropY, cropW, cropH);
      darkImg.crop(cropX, cropY, cropW, cropH);
      
      await lightImg.writeAsync(destLight);
      await darkImg.writeAsync(destDark);
      console.log('Saved transparent logos to:');
      console.log('Light:', destLight);
      console.log('Dark:', destDark);
      console.log('Dimensions:', lightImg.bitmap.width, 'x', lightImg.bitmap.height);
    } else {
      console.log('Failed to detect logo bounding box');
    }
  })
  .catch(err => {
    console.error('Error processing logos:', err);
  });
