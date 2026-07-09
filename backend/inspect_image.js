const Jimp = require('jimp');

Jimp.read('C:\\Users\\asus\\.gemini\\antigravity-ide\\brain\\253af99c-1cf0-4d24-83dc-3eb5636aa0a3\\media__1781605742738.png')
  .then(image => {
    console.log('Dimensions:', image.bitmap.width, 'x', image.bitmap.height);
    // Print top-left corner colors
    for (let y = 0; y < 10; y++) {
      let row = [];
      for (let x = 0; x < 10; x++) {
        const hex = image.getPixelColor(x, y).toString(16).padStart(8, '0');
        row.push(hex);
      }
      console.log(`Row ${y}:`, row.join(' '));
    }
  })
  .catch(err => {
    console.error(err);
  });
