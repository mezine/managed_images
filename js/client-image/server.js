var md5 = require('md5');
var is = require('./is-assertions');
var ClientImage = require('./index');
var Variant = require('./variant');
var Promise = require('bluebird');

ClientImage.configureServer = function (opts) {
  is(opts.salt, 'string');
  is(opts.baseUrl, 'string');
  ClientImage.salt = opts.salt;
  ClientImage.baseUrl = opts.baseUrl;
  ClientImage.generateHexdigest = function (s) {
    return md5.digest_s(s);
  };
};

ClientImage.prototype.getVariant = function (width, height, x1, x2, y1, y2) {
  var variant = new Variant(this, width, height, x1, x2, y1, y2);
  variant.setHexdigest(ClientImage.generateHexdigest(variant.path));
  var hexdigest = ClientImage.generateHexdigest(variant.path);
  return Promise.resolve(variant);
};

module.exports = ClientImage;