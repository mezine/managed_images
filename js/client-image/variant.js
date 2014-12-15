var is = require('./is-assertions');
var ClientImage = require('./index');

var Variant = function (image, width, height, x1, x2, y1, y2) {
  is(image, ClientImage);
  is(width, 'number');
  is(height, 'number');
  is(x1, 'number');
  is(x2, 'number');
  is(y1, 'number');
  is(y2, 'number');
  this.image = image;
  this.width = width;
  this.height = height;
  this.x1 = x1;
  this.x2 = x2;
  this.y1 = y1;
  this.y2 = y2;
  var info = this.image.getInfo();
  var fileName = [info.baseName, width, height, x1, x2, y1, y2].join('-') + '.' + info.extName;
  this.path = [info.dir, fileName].join('/');
};

Variant.prototype.setHexdigest = function (hexdigest) {
  is(hexdigest, 'string');
  this.hexdigest = hexdigest;
};

Variant.prototype.getUrl = function () {

};

module.exports = Variant;