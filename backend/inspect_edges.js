const Jimp = require('jimp');

Jimp.read('C:\\Users\\asus\\.gemini\\antigravity-ide\\brain\\253af99c-1cf0-4d24-83dc-3eb5636aa0a3\\media__1781605742738.png')
  .then(image => {
    const w = image.bitmap.width;
    const h = image.bitmap.height;
    
    // Find all distinct colors and check if they are near the edges
    const colors = new Map();
    for (let y = 0; y < h; y++) {
      for (let x = 0; x < w; x++) {
        const c = image.getPixelColor(x, y).toString(16).padStart(8, '0');
        colors.set(c, (colors.get(c) || 0) + 1);
      }
    }
    
    // Print top 10 most common colors
    const sorted = [...colors.entries()].sort((a, b) => b[1] - a[1]);
    console.log('Top colors:');
    sorted.slice(0, 10).forEach(([c, count]) => {
      console.log(`Color #${c}: ${count} pixels`);
    });
    
    // Let's check the border of the image (first/last rows and columns)
    const edgeColors = new Map();
    for (let x = 0; x < w; x++) {
      const c1 = image.getPixelColor(x, 0).toString(16).padStart(8, '0');
      const c2 = image.getPixelColor(x, h - 1).toString(16).padStart(8, '0');
      edgeColors.set(c1, (edgeColors.get(c1) || 0) + 1);
      edgeColors.set(c2, (edgeColors.get(c2) || 0) + 1);
    }
    for (let y = 0; y < h; y++) {
      const c1 = image.getPixelColor(0, y).toString(16).padStart(8, '0');
      const c2 = image.getPixelColor(w - 1, y).toString(16).padStart(8, '0');
      edgeColors.set(c1, (edgeColors.get(c1) || 0) + 1);
      edgeColors.set(c2, (edgeColors.get(c2) || 0) + 1);
    }
    console.log('Edge colors:');
    [...edgeColors.entries()].sort((a, b) => b[1] - a[1]).slice(0, 5).forEach(([c, count]) => {
      console.log(`Edge Color #${c}: ${count} pixels`);
    });
  })
  .catch(err => console.error(err));
