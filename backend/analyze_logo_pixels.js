const Jimp = require('jimp');

Jimp.read('C:\\Users\\asus\\.gemini\\antigravity-ide\\brain\\253af99c-1cf0-4d24-83dc-3eb5636aa0a3\\scratch\\logo_transparent.png')
  .then(image => {
    const w = image.bitmap.width;
    const h = image.bitmap.height;
    
    // We want to classify colors:
    // 1. Teal/green: e.g. arrow and "REMINDER" text
    // 2. Dark navy/indigo: e.g. "eazzio" text
    // Let's sample colors of pixels that are non-transparent (alpha > 50)
    const colorGroups = new Map();
    for (let y = 0; y < h; y++) {
      for (let x = 0; x < w; x++) {
        const color = image.getPixelColor(x, y);
        const a = color & 0xff;
        if (a > 50) {
          const r = (color >> 24) & 0xff;
          const g = (color >> 16) & 0xff;
          const b = (color >> 8) & 0xff;
          
          // Let's group by hue/saturation/value or rough color categorization
          // Navy is dark and blue-ish: high B, low R/G, low brightness
          // Teal/green is high G, moderate/high R/B, bright
          // Let's compute simple channels
          let category = '';
          if (g > r + 30 && g > b) {
            category = 'green/teal';
          } else if (b > r && b > g && (r + g + b) < 250) {
            category = 'navy/dark';
          } else {
            category = 'other';
          }
          
          const key = `${category} (rgb: ${r},${g},${b})`;
          colorGroups.set(category, (colorGroups.get(category) || 0) + 1);
        }
      }
    }
    console.log('Pixel color categories:', colorGroups);
  })
  .catch(err => console.error(err));
