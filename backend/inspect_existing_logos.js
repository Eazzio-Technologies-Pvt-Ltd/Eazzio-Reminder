const Jimp = require('jimp');

Promise.all([
  Jimp.read('c:\\Users\\asus\\OneDrive\\Desktop\\eazzio-reminder\\frontend\\assets\\images\\logo_light.png').catch(() => null),
  Jimp.read('c:\\Users\\asus\\OneDrive\\Desktop\\eazzio-reminder\\frontend\\assets\\images\\logo_dark.png').catch(() => null)
]).then(([light, dark]) => {
  if (light) {
    console.log('logo_light.png:', light.bitmap.width, 'x', light.bitmap.height);
  } else {
    console.log('logo_light.png does not exist or failed to load');
  }
  if (dark) {
    console.log('logo_dark.png:', dark.bitmap.width, 'x', dark.bitmap.height);
  } else {
    console.log('logo_dark.png does not exist or failed to load');
  }
});
