var is = function (value, type) {
  if ((typeof value !== type) && !(value instanceof type)) {
    throw "value which is " + value + " must be of type " + type;
  }
}

is.assert = function (pass, msg) {
  if (!pass) {
    throw msg;
  }
}

module.exports = is;