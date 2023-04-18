module.exports = (function() {
var __MODS__ = {};
var __DEFINE__ = function(modId, func, req) { var m = { exports: {}, _tempexports: {} }; __MODS__[modId] = { status: 0, func: func, req: req, m: m }; };
var __REQUIRE__ = function(modId, source) { if(!__MODS__[modId]) return require(source); if(!__MODS__[modId].status) { var m = __MODS__[modId].m; m._exports = m._tempexports; var desp = Object.getOwnPropertyDescriptor(m, "exports"); if (desp && desp.configurable) Object.defineProperty(m, "exports", { set: function (val) { if(typeof val === "object" && val !== m._exports) { m._exports.__proto__ = val.__proto__; Object.keys(val).forEach(function (k) { m._exports[k] = val[k]; }); } m._tempexports = val }, get: function () { return m._tempexports; } }); __MODS__[modId].status = 1; __MODS__[modId].func(__MODS__[modId].req, m, m.exports); } return __MODS__[modId].m.exports; };
var __REQUIRE_WILDCARD__ = function(obj) { if(obj && obj.__esModule) { return obj; } else { var newObj = {}; if(obj != null) { for(var k in obj) { if (Object.prototype.hasOwnProperty.call(obj, k)) newObj[k] = obj[k]; } } newObj.default = obj; return newObj; } };
var __REQUIRE_DEFAULT__ = function(obj) { return obj && obj.__esModule ? obj.default : obj; };
__DEFINE__(1681364781939, function(require, module, exports) {

var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __exportStar = (this && this.__exportStar) || function(m, exports) {
    for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports, p)) __createBinding(exports, m, p);
};
Object.defineProperty(exports, "__esModule", { value: true });
__exportStar(require("./traits"), exports);
__exportStar(require("./types"), exports);
__exportStar(require("./helpers"), exports);

}, function(modId) {var map = {"./traits":1681364781940,"./types":1681364781941,"./helpers":1681364781942}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364781940, function(require, module, exports) {

var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.Jluetooth = void 0;
/**
 * absctract bluetooth class
 */
class Jluetooth {
    isDiscovery() {
        return __awaiter(this, void 0, void 0, function* () {
            const state = yield this.bluetoothAdapterState();
            return state.discovering || false;
        });
    }
}
exports.Jluetooth = Jluetooth;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364781941, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.AllowRule = exports.JluetoothDevice = void 0;
class JluetoothDevice {
    constructor(options) {
        this.origin = options.origin;
        this.name = options.name;
        this.deviceId = options.deviceId;
    }
}
exports.JluetoothDevice = JluetoothDevice;
var AllowRule;
(function (AllowRule) {
    AllowRule["EQUALS"] = "EQUALS";
    AllowRule["START_WITH"] = "START_WITH";
    AllowRule["END_WITH"] = "END_WITH";
    AllowRule["REGEX"] = "REGEX";
})(AllowRule = exports.AllowRule || (exports.AllowRule = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364781942, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TBluetoothHelpers = void 0;
const types_1 = require("./types");
class TBluetoothHelpers {
    static isAllowService(serviceUUID, allowService) {
        return this.isAllowServices(serviceUUID, allowService && [allowService]);
    }
    static isAllowServices(serviceUUID, allowServices) {
        var _a;
        if (allowServices == undefined)
            return true;
        for (const allowService of allowServices) {
            const rule = (_a = allowService.rule) !== null && _a !== void 0 ? _a : types_1.AllowRule.EQUALS;
            switch (rule) {
                case types_1.AllowRule.EQUALS: {
                    if (serviceUUID == allowService.uuid)
                        return true;
                    break;
                }
                case types_1.AllowRule.START_WITH: {
                    if (serviceUUID.startsWith(allowService.uuid))
                        return true;
                    break;
                }
                case types_1.AllowRule.END_WITH: {
                    if (serviceUUID.endsWith(allowService.uuid))
                        return true;
                    break;
                }
                case types_1.AllowRule.REGEX: {
                    if (new RegExp(allowService.uuid).test(serviceUUID))
                        return true;
                    break;
                }
            }
        }
    }
}
exports.TBluetoothHelpers = TBluetoothHelpers;

}, function(modId) { var map = {"./types":1681364781941}; return __REQUIRE__(map[modId], modId); })
return __REQUIRE__(1681364781939);
})()
//miniprogram-npm-outsideDeps=[]
//# sourceMappingURL=index.js.map