var md5 = require('md5');
var is = require('./is-assertions');
var ClientImage = require('./index');
var Variant = require('./variant');
var Promise = require('bluebird');
var $ = require('jquery');
var Ajax = require('ajax-promise');

ClientImage.configureBrowser = function (opts) {
  is(opts.variantUrl, 'string');
  is(opts.baseUrl, 'string');
  ClientImage.variantUrl = opts.variantUrl;
  ClientImage.baseUrl = opts.baseUrl;
};

ClientImage.prototype.getVariant = function (width, height, x1, x2, y1, y2) {
  var variant = new Variant(this, width, height, x1, x2, y1, y2);
  var promise = new Promise(function (resolve, reject) {
    Ajax.get(ClientImage.variantUrl, {path: variant.path}).then(function (data) {
      $.extend(variant, data);
      resolve(variant);
    }).catch(function (e) {
      reject(e);
    });
  });
  return promise;
};

module.exports = ClientImage;