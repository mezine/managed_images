var is = require('./is-assertions');
var assert = is.assert;

var ClientImage = function (path, width, height) {
  is(path, 'string');
  is(width, 'number');
  is(height, 'number');
  this.path = path;
  this.width = width;
  this.height = height;
};

ClientImage.prototype.getInfo = function () {
  var segments = this.path.split('/');
  var fileName = segments.pop();
  var dir = segments.join('/');
  var fileNameSegments = fileName.split('.');
  var baseName = fileNameSegments[0];
  var extName = fileNameSegments[1];
  return {
    fileName: fileName,
    baseName: baseName,
    extName: extName,
    dir: dir
  };
};

module.exports = ClientImage;

var Variant = require('./variant');
ClientImage.Variant = Variant;

