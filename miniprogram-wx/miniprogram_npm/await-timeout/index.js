module.exports = (function() {
var __MODS__ = {};
var __DEFINE__ = function(modId, func, req) { var m = { exports: {}, _tempexports: {} }; __MODS__[modId] = { status: 0, func: func, req: req, m: m }; };
var __REQUIRE__ = function(modId, source) { if(!__MODS__[modId]) return require(source); if(!__MODS__[modId].status) { var m = __MODS__[modId].m; m._exports = m._tempexports; var desp = Object.getOwnPropertyDescriptor(m, "exports"); if (desp && desp.configurable) Object.defineProperty(m, "exports", { set: function (val) { if(typeof val === "object" && val !== m._exports) { m._exports.__proto__ = val.__proto__; Object.keys(val).forEach(function (k) { m._exports[k] = val[k]; }); } m._tempexports = val }, get: function () { return m._tempexports; } }); __MODS__[modId].status = 1; __MODS__[modId].func(__MODS__[modId].req, m, m.exports); } return __MODS__[modId].m.exports; };
var __REQUIRE_WILDCARD__ = function(obj) { if(obj && obj.__esModule) { return obj; } else { var newObj = {}; if(obj != null) { for(var k in obj) { if (Object.prototype.hasOwnProperty.call(obj, k)) newObj[k] = obj[k]; } } newObj.default = obj; return newObj; } };
var __REQUIRE_DEFAULT__ = function(obj) { return obj && obj.__esModule ? obj.default : obj; };
__DEFINE__(1715917494106, function(require, module, exports) {
/**
 * Promise-based replacement for setTimeout / clearTimeout.
 */

const {promiseFinally, toError} = require('./utils');

module.exports = class Timeout {
  static set(delay, rejectReason) {
    return new Timeout().set(delay, rejectReason);
  }

  static wrap(promise, delay, rejectReason) {
    return new Timeout().wrap(promise, delay, rejectReason);
  }

  constructor() {
    this._id = null;
    this._delay = null;
  }

  get id() {
    return this._id;
  }

  get delay() {
    return this._delay;
  }

  set(delay, rejectReason = '') {
    return new Promise((resolve, reject) => {
      this.clear();
      const fn = rejectReason ? () => reject(toError(rejectReason)) : resolve;
      this._id = setTimeout(fn, delay);
      this._delay = delay;
    });
  }

  wrap(promise, delay, rejectReason = '') {
    const wrappedPromise = promiseFinally(promise, () => this.clear());
    const timer = this.set(delay, rejectReason);
    return Promise.race([
      wrappedPromise,
      timer
    ]);
  }

  clear() {
    if (this._id) {
      clearTimeout(this._id);
    }
  }
};

}, function(modId) {var map = {"./utils":1715917494107}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494107, function(require, module, exports) {
exports.promiseFinally = (promise, fn) => {
  const success = result => {
    fn();
    return result;
  };
  const error = e => {
    fn();
    return Promise.reject(e);
  };
  return Promise.resolve(promise).then(success, error);
};

/**
 * Converts any value to Error.
 * @param {*} value
 * @returns {Error}
 */
exports.toError = value => {
  value = typeof value === 'function' ? value() : value;
  return typeof value === 'string' ? new Error(value) : value;
};

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
return __REQUIRE__(1715917494106);
})()
//miniprogram-npm-outsideDeps=[]
//# sourceMappingURL=index.js.map