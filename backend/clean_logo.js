const Jimp = require('jimp');
const path = require('path');

const logoLightPath = 'c:\\Users\\asus\\OneDrive\\Desktop\\eazzio-reminder\\frontend\\assets\\images\\logo_light.png';
const logoDarkPath = 'c:\\Users\\asus\\OneDrive\\Desktop\\eazzio-reminder\\frontend\\assets\\images\\logo_dark.png';

Jimp.read(logoLightPath)
  .then(async (image) => {
    const w = image.bitmap.width;
    const h = image.bitmap.height;
    
    console.log(`Processing light logo of size ${w}x${h}...`);
    
    // 1. Clean up white/light-gray pixels from light logo
    // These are residual backgrounds inside counter holes (like e, a, z, o, R, D)
    for (let y = 0; y < h; y++) {
      for (let x = 0; x < w; x++) {
        const color = image.getPixelColor(x, y);
        const r = (color >> 24) & 0xff;
        const g = (color >> 16) & 0xff;
        const b = (color >> 8) & 0xff;
        const a = color & 0xff;
        
        if (a > 0) {
          // If the pixel is very bright/white-ish
          if (r > 200 && g > 200 && b > 200) {
            // Make it transparent
            image.setPixelColor(0x00000000, x, y);
          }
        }
      }
    }
    
    // Save the cleaned light logo
    await image.writeAsync(logoLightPath);
    console.log('Saved cleaned logo_light.png successfully.');
    
    // 2. Generate the dark logo from the cleaned light logo
    const darkImage = image.clone();
    
    for (let y = 0; y < h; y++) {
      for (let x = 0; x < w; x++) {
        const color = darkImage.getPixelColor(x, y);
        const r = (color >> 24) & 0xff;
        const g = (color >> 16) & 0xff;
        const b = (color >> 8) & 0xff;
        const a = color & 0xff;
        
        if (a > 10) {
          // Identify if it is NOT green/teal text
          const isGreenTeal = (g > r + 25) && (g > b - 30);
          
          if (!isGreenTeal) {
            // Convert dark navy/black text to white, keeping the original alpha
            const whiteColor = (((0xff << 24) | (0xff << 16) | (0xff << 8) | a) >>> 0);
            darkImage.setPixelColor(whiteColor, x, y);
          }
        }
      }
    }
    
    // Save the regenerated dark logo
    await darkImage.writeAsync(logoDarkPath);
    console.log('Saved regenerated logo_dark.png successfully.');
  })
  .catch(err => {
    console.error('Error processing logos:', err);
  });
