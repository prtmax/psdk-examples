module.exports = (function() {
var __MODS__ = {};
var __DEFINE__ = function(modId, func, req) { var m = { exports: {}, _tempexports: {} }; __MODS__[modId] = { status: 0, func: func, req: req, m: m }; };
var __REQUIRE__ = function(modId, source) { if(!__MODS__[modId]) return require(source); if(!__MODS__[modId].status) { var m = __MODS__[modId].m; m._exports = m._tempexports; var desp = Object.getOwnPropertyDescriptor(m, "exports"); if (desp && desp.configurable) Object.defineProperty(m, "exports", { set: function (val) { if(typeof val === "object" && val !== m._exports) { m._exports.__proto__ = val.__proto__; Object.keys(val).forEach(function (k) { m._exports[k] = val[k]; }); } m._tempexports = val }, get: function () { return m._tempexports; } }); __MODS__[modId].status = 1; __MODS__[modId].func(__MODS__[modId].req, m, m.exports); } return __MODS__[modId].m.exports; };
var __REQUIRE_WILDCARD__ = function(obj) { if(obj && obj.__esModule) { return obj; } else { var newObj = {}; if(obj != null) { for(var k in obj) { if (Object.prototype.hasOwnProperty.call(obj, k)) newObj[k] = obj[k]; } } newObj.default = obj; return newObj; } };
var __REQUIRE_DEFAULT__ = function(obj) { return obj && obj.__esModule ? obj.default : obj; };
__DEFINE__(1790237021547, function(require, module, exports) {
var __assign = (this && this.__assign) || function () {
    __assign = Object.assign || function(t) {
        for (var s, i = 1, n = arguments.length; i < n; i++) {
            s = arguments[i];
            for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
                t[p] = s[p];
        }
        return t;
    };
    return __assign.apply(this, arguments);
};
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g = Object.create((typeof Iterator === "function" ? Iterator : Object).prototype);
    return g.next = verb(0), g["throw"] = verb(1), g["return"] = verb(2), typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
var X = Object.create;
var g = Object.defineProperty;
var j = Object.getOwnPropertyDescriptor;
var z = Object.getOwnPropertyNames;
var K = Object.getPrototypeOf, Y = Object.prototype.hasOwnProperty;
var Z = function (i, e, t) { return e in i ? g(i, e, { enumerable: !0, configurable: !0, writable: !0, value: t }) : i[e] = t; };
var T = function (i, e) { return function () { return (e || i((e = { exports: {} }).exports, e), e.exports); }; }, ee = function (i, e) { for (var t in e)
    g(i, t, { get: e[t], enumerable: !0 }); }, x = function (i, e, t, r) { if (e && typeof e == "object" || typeof e == "function") {
    var _loop_1 = function (s) {
        !Y.call(i, s) && s !== t && g(i, s, { get: function () { return e[s]; }, enumerable: !(r = j(e, s)) || r.enumerable });
    };
    for (var _i = 0, _a = z(e); _i < _a.length; _i++) {
        var s = _a[_i];
        _loop_1(s);
    }
} return i; };
var S = function (i, e, t) { return (t = i != null ? X(K(i)) : {}, x(e || !i || !i.__esModule ? g(t, "default", { value: i, enumerable: !0 }) : t, i)); }, te = function (i) { return x(g({}, "__esModule", { value: !0 }), i); };
var v = function (i, e, t) { return Z(i, typeof e != "symbol" ? e + "" : e, t); };
var _ = T(function (O) { O.promiseFinally = function (i, e) { var t = function (s) { return (e(), s); }, r = function (s) { return (e(), Promise.reject(s)); }; return Promise.resolve(i).then(t, r); }; O.toError = function (i) { return (i = typeof i == "function" ? i() : i, typeof i == "string" ? new Error(i) : i); }; });
var M = T(function (ge, H) { var _a = _(), ie = _a.promiseFinally, re = _a.toError; H.exports = (function () {
    function A() {
        this._id = null, this._delay = null;
    }
    A.set = function (e, t) { return new A().set(e, t); };
    A.wrap = function (e, t, r) { return new A().wrap(e, t, r); };
    Object.defineProperty(A.prototype, "id", {
        get: function () { return this._id; },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(A.prototype, "delay", {
        get: function () { return this._delay; },
        enumerable: false,
        configurable: true
    });
    A.prototype.set = function (e, t) {
        var _this = this;
        if (t === void 0) { t = ""; }
        return new Promise(function (r, s) { _this.clear(); var n = t ? function () { return s(re(t)); } : r; _this._id = setTimeout(n, e), _this._delay = e; });
    };
    A.prototype.wrap = function (e, t, r) {
        var _this = this;
        if (r === void 0) { r = ""; }
        var s = ie(e, function () { return _this.clear(); }), n = this.set(t, r);
        return Promise.race([s, n]);
    };
    A.prototype.clear = function () { this._id && clearTimeout(this._id); };
    return A;
}()); });
var U = T(function (Be, Q) { var P = Object.defineProperty, se = Object.getOwnPropertyDescriptor, ae = Object.getOwnPropertyNames, oe = Object.prototype.hasOwnProperty, ce = function (i, e, t) { return e in i ? P(i, e, { enumerable: !0, configurable: !0, writable: !0, value: t }) : i[e] = t; }, ne = function (i, e) { for (var t in e)
    P(i, t, { get: e[t], enumerable: !0 }); }, le = function (i, e, t, r) { if (e && typeof e == "object" || typeof e == "function") {
    var _loop_2 = function (s) {
        !oe.call(i, s) && s !== t && P(i, s, { get: function () { return e[s]; }, enumerable: !(r = se(e, s)) || r.enumerable });
    };
    for (var _i = 0, _a = ae(e); _i < _a.length; _i++) {
        var s = _a[_i];
        _loop_2(s);
    }
} return i; }, de = function (i) { return le(P({}, "__esModule", { value: !0 }), i); }, u = function (i, e, t) { return ce(i, typeof e != "symbol" ? e + "" : e, t); }, J = {}; ne(J, { AllowRule: function () { return G; }, BleFlowControlWriter: function () { return pe; }, DEFAULT_BLE_FLOW_CONTROL_OPTIONS: function () { return C; }, Jluetooth: function () { return ue; }, JluetoothDevice: function () { return he; }, TBluetoothHelpers: function () { return ve; }, findBleFlowControlCharacteristics: function () { return we; }, isBleShortUuidMatch: function () { return B; }, isBleUuidMatch: function () { return fe; }, normalizeBleUuid: function () { return E; } }); Q.exports = de(J); var ue = (function () {
    function class_1() {
    }
    class_1.prototype.isDiscovery = function () {
        return __awaiter(this, void 0, void 0, function () { return __generator(this, function (_a) {
            switch (_a.label) {
                case 0: return [4, this.bluetoothAdapterState()];
                case 1: return [2, (_a.sent()).discovering || !1];
            }
        }); });
    };
    return class_1;
}()), he = (function () {
    function he(i) {
        u(this, "origin"), u(this, "name"), u(this, "deviceId"), u(this, "mac"), u(this, "rssi"), u(this, "advertisData"), this.origin = i.origin, this.name = i.name, this.deviceId = i.deviceId, this.mac = i.mac, this.rssi = i.rssi, this.advertisData = i.advertisData;
    }
    return he;
}()), G = (function (i) { return (i.EQUALS = "EQUALS", i.START_WITH = "START_WITH", i.END_WITH = "END_WITH", i.REGEX = "REGEX", i); })(G || {}), C = { enabled: !1, serviceUUID: "FF00", writeCharacteristicUUID: "FF02", readCharacteristicUUID: "FF01", flowControlCharacteristicUUID: "FF03", initialMtu: 20, mtuPayloadOverhead: 3, creditWaitTimeout: 0 }, ve = (function () {
    function ve() {
    }
    ve.isAllowService = function (i, e) { return this.isAllowServices(i, e && [e]); };
    ve.isAllowServices = function (i, e) { var t; if (e == null)
        return !0; for (var _i = 0, e_1 = e; _i < e_1.length; _i++) {
        var r = e_1[_i];
        switch ((t = r.rule) != null ? t : "EQUALS") {
            case "EQUALS": {
                if (i == r.uuid)
                    return !0;
                break;
            }
            case "START_WITH": {
                if (i.startsWith(r.uuid))
                    return !0;
                break;
            }
            case "END_WITH": {
                if (i.endsWith(r.uuid))
                    return !0;
                break;
            }
            case "REGEX": {
                if (new RegExp(r.uuid).test(i))
                    return !0;
                break;
            }
        }
    } };
    return ve;
}()); function E(i) { return i.replace(/-/g, "").toLowerCase(); } function fe(i, e) { return E(i) === E(e); } function B(i, e) { var t = E(i), r = E(e); return t === r || t.startsWith("0000".concat(r)); } function we(i) { var e = __assign(__assign({}, C), i.flowControlOptions); for (var _i = 0, _a = i.services; _i < _a.length; _i++) {
    var t = _a[_i];
    if (i.isServiceAllowed && !i.isServiceAllowed(t) || !B(i.getServiceUuid(t), e.serviceUUID))
        continue;
    var r = i.getCharacteristics(t);
    if (!r)
        continue;
    var s = r.find(function (o) { return B(i.getCharacteristicUuid(o), e.writeCharacteristicUUID); }), n = r.find(function (o) { return B(i.getCharacteristicUuid(o), e.readCharacteristicUUID); }), c = r.find(function (o) { return B(i.getCharacteristicUuid(o), e.flowControlCharacteristicUUID); });
    if (s && n && c)
        return { service: t, write: s, read: n, flowControl: c };
} } var pe = (function () {
    function class_2(i) {
        if (i === void 0) { i = {}; }
        u(this, "mtu"), u(this, "mtuPayloadOverhead"), u(this, "credit", 0), u(this, "creditWaitTimeout"), u(this, "sleep"), u(this, "now"), u(this, "writePromise", Promise.resolve());
        var e, t, r, s, n;
        var c = (e = i.initialMtu) != null ? e : C.initialMtu;
        this.mtu = c > 0 ? c : C.initialMtu;
        var o = (t = i.mtuPayloadOverhead) != null ? t : C.mtuPayloadOverhead;
        this.mtuPayloadOverhead = o >= 0 ? o : C.mtuPayloadOverhead, this.creditWaitTimeout = (r = i.creditWaitTimeout) != null ? r : C.creditWaitTimeout, this.sleep = (s = i.sleep) != null ? s : function (p) { return new Promise(function (m) { return setTimeout(m, p); }); }, this.now = (n = i.now) != null ? n : function () { return Date.now(); };
    }
    class_2.prototype.state = function () { return { mtu: this.mtu, payloadMtu: this.payloadMtu(), credit: this.credit }; };
    class_2.prototype.parseNotifyPacket = function (i) { if (i.length !== 0)
        switch ((console.log("[BLE FC] notify", Array.from(i)), i[0])) {
            case 1: {
                if (i.length >= 2) {
                    var e = i[1];
                    e > this.credit ? this.credit = e : this.credit += e, console.log("[BLE FC] credit:", this.credit);
                }
                break;
            }
            case 2: {
                if (i.length >= 3) {
                    var e = i[1] | i[2] << 8;
                    e > 0 && (this.mtu = e), console.log("[BLE FC] mtu:", this.mtu);
                }
                break;
            }
        } };
    class_2.prototype.onNotify = function (i) { this.parseNotifyPacket(i); };
    class_2.prototype.write = function (i, e) {
        return __awaiter(this, void 0, void 0, function () {
            var t;
            var _this = this;
            return __generator(this, function (_a) {
                t = this.writePromise.catch(function () { }).then(function () { return _this.writeUnlocked(i, e); });
                return [2, (this.writePromise = t, t)];
            });
        });
    };
    class_2.prototype.writeUnlocked = function (i, e) {
        return __awaiter(this, void 0, void 0, function () { var t, r, s; return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    t = 0;
                    _a.label = 1;
                case 1:
                    if (!(t < i.length)) return [3, 5];
                    return [4, this.waitForCredit()];
                case 2:
                    _a.sent();
                    r = this.payloadMtu();
                    this.credit -= 1;
                    s = i.slice(t, t + r);
                    console.log("[BLE FC] write chunk:", s.length, "credit:", this.credit);
                    return [4, e.writeChunk(s)];
                case 3:
                    _a.sent(), t += r;
                    _a.label = 4;
                case 4: return [3, 1];
                case 5: return [2];
            }
        }); });
    };
    class_2.prototype.payloadMtu = function () { var i = this.mtu - this.mtuPayloadOverhead; return i > 0 ? i : 1; };
    class_2.prototype.waitForCredit = function () {
        return __awaiter(this, void 0, void 0, function () { var i; return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    i = this.now();
                    _a.label = 1;
                case 1:
                    if (!(this.credit <= 0)) return [3, 4];
                    if (this.creditWaitTimeout > 0 && this.now() - i >= this.creditWaitTimeout)
                        throw new Error("Timeout waiting for BLE flow-control credit");
                    return [4, this.sleep(20)];
                case 2:
                    _a.sent();
                    _a.label = 3;
                case 3: return [3, 1];
                case 4: return [2];
            }
        }); });
    };
    return class_2;
}()); });
var me = {};
ee(me, { WechatBleBluetooth: function () { return b; }, WechatBleConnectedDevice: function () { return D; } });
module.exports = te(me);
var V = S(M()), L = S(U());
var I = { CONNECTED: "CONNECTED", DISCONNECTED: "DISCONNECTED" }, D = (function () {
    function class_3(e) {
        v(this, "device");
        v(this, "scpair");
        v(this, "flowControlWriter");
        v(this, "_connectionState");
        v(this, "dataOfRead");
        v(this, "notifyCallback");
        v(this, "notifyReady");
        this.device = e.device, this.scpair = e.scpair, this._connectionState = I.CONNECTED, this.dataOfRead = [], this.flowControlWriter = this.createFlowControlWriter(e.flowControl), this.notifyReady = this.doListen();
    }
    class_3.prototype.notify = function (e) { this.notifyCallback = e; };
    class_3.prototype.doListen = function () {
        return __awaiter(this, void 0, void 0, function () {
            var _a, _b;
            var _this = this;
            return __generator(this, function (_c) {
                switch (_c.label) {
                    case 0:
                        wx.onBLECharacteristicValueChange(function (e) { return __awaiter(_this, void 0, void 0, function () { var t, _a, _b, _c; return __generator(this, function (_d) {
                            switch (_d.label) {
                                case 0:
                                    t = new Uint8Array(e.value);
                                    if (this.flowControlWriter && this.scpair.flowControl && e.characteristicId && this.isSameCharacteristicUuid(e.characteristicId, this.scpair.flowControl.uuid)) {
                                        this.notifyFlowControl(t);
                                        return [2];
                                    }
                                    _a = this.scpair.read;
                                    if (!_a) return [3, 4];
                                    _b = e.characteristicId && !this.isSameCharacteristicUuid(e.characteristicId, this.scpair.read.uuid);
                                    if (_b) return [3, 3];
                                    _c = this.notifyCallback;
                                    if (!_c) return [3, 2];
                                    return [4, this.notifyCallback(t)];
                                case 1:
                                    _c = (_d.sent());
                                    _d.label = 2;
                                case 2:
                                    _b = (_c, this.dataOfRead.push(t));
                                    _d.label = 3;
                                case 3:
                                    _a = (_b);
                                    _d.label = 4;
                                case 4:
                                    _a;
                                    return [2];
                            }
                        }); }); }), wx.onBLEConnectionStateChange(function (e) { _this._connectionState = e.connected ? I.CONNECTED : I.DISCONNECTED; });
                        _a = this.scpair.read != null;
                        if (!_a) return [3, 2];
                        return [4, this.enableNotify(this.scpair.read.uuid)];
                    case 1:
                        _a = (_c.sent());
                        _c.label = 2;
                    case 2:
                        _a;
                        _b = this.scpair.flowControl != null;
                        if (!_b) return [3, 4];
                        return [4, this.enableNotify(this.scpair.flowControl.uuid)];
                    case 3:
                        _b = (_c.sent());
                        _c.label = 4;
                    case 4:
                        _b;
                        return [2];
                }
            });
        });
    };
    class_3.prototype.enableNotify = function (e) {
        return __awaiter(this, void 0, void 0, function () {
            var _this = this;
            return __generator(this, function (_a) {
                return [2, new Promise(function (t, r) { wx.notifyBLECharacteristicValueChange({ deviceId: _this.device.deviceId, serviceId: _this.scpair.service.uuid, characteristicId: e, state: !0, success: function (s) { console.log(s), t(); }, fail: function (s) { return r(s); } }); })];
            });
        });
    };
    class_3.prototype.createFlowControlWriter = function (e) { var t; if (!(!this.scpair.flowControl || !((t = e == null ? void 0 : e.enabled) != null && t)))
        return new L.BleFlowControlWriter(__assign(__assign({}, L.DEFAULT_BLE_FLOW_CONTROL_OPTIONS), e)); };
    class_3.prototype.notifyFlowControl = function (e) { this.flowControlWriter.onNotify(e); };
    class_3.prototype.isSameCharacteristicUuid = function (e, t) { return e.replace(/-/g, "").toLowerCase() == t.replace(/-/g, "").toLowerCase(); };
    class_3.prototype.writeChunk = function (e) {
        return __awaiter(this, void 0, void 0, function () {
            var _this = this;
            return __generator(this, function (_a) {
                return [2, new Promise(function (t, r) { wx.writeBLECharacteristicValue({ deviceId: _this.device.deviceId, serviceId: _this.scpair.service.uuid, characteristicId: _this.scpair.write.uuid, writeType: "writeNoResponse", value: e.buffer, success: function (s) { if (s.errMsg.indexOf("ok") == -1) {
                            r(s.errMsg);
                            return;
                        } t(); }, fail: function (s) { return r(s); } }); })];
            });
        });
    };
    class_3.prototype.realRead = function () {
        return __awaiter(this, void 0, void 0, function () {
            var _this = this;
            return __generator(this, function (_a) {
                return [2, new Promise(function (e, t) { if (_this.scpair.read == null) {
                        t("the connect device not support read operation: service id: [".concat(_this.scpair.service.uuid, "]"));
                        return;
                    } wx.readBLECharacteristicValue({ deviceId: _this.device.deviceId, serviceId: _this.scpair.service.uuid, characteristicId: _this.scpair.read.uuid, success: function (r) { if (r.errMsg.indexOf("ok") == -1) {
                            t(r.errMsg);
                            return;
                        } e(); }, fail: function (r) { return t(r); } }); })];
            });
        });
    };
    class_3.prototype.origin = function () { return this.device; };
    class_3.prototype.connectionState = function () { return this._connectionState; };
    class_3.prototype.deviceName = function () { return this.device.localName || this.device.name || "NONE"; };
    class_3.prototype.disconnect = function () {
        return __awaiter(this, void 0, void 0, function () {
            var _this = this;
            return __generator(this, function (_a) {
                return [2, new Promise(function (e, t) { wx.closeBLEConnection({ deviceId: _this.device.deviceId, success: function () { _this.device = null, _this.scpair = null, _this._connectionState = I.DISCONNECTED, e(); }, fail: function (r) { return t(r); } }); })];
            });
        });
    };
    class_3.prototype.canRead = function () { return this.scpair.read != null; };
    class_3.prototype.read = function (e) {
        return __awaiter(this, void 0, void 0, function () { var s, t, r, c; return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    this.dataOfRead.length > 0 && this.dataOfRead.splice(0, this.dataOfRead.length);
                    return [4, this.realRead()];
                case 1:
                    _a.sent();
                    t = (s = e == null ? void 0 : e.timeout) != null ? s : 5e3, r = +new Date;
                    _a.label = 2;
                case 2:
                    if (+new Date - r > t)
                        return [2, new Uint8Array([])];
                    if (!(this.dataOfRead.length == 0)) return [3, 4];
                    return [4, V.default.set(100)];
                case 3:
                    _a.sent();
                    return [3, 5];
                case 4:
                    c = this.dataOfRead.pop();
                    return [2, new Uint8Array(c)];
                case 5: return [3, 2];
                case 6: return [2];
            }
        }); });
    };
    class_3.prototype.write = function (e) {
        return __awaiter(this, void 0, void 0, function () {
            var _a;
            var _this = this;
            return __generator(this, function (_b) {
                switch (_b.label) {
                    case 0:
                        if (!this.flowControlWriter) return [3, 2];
                        return [4, this.notifyReady];
                    case 1:
                        _a = (_b.sent(), this.flowControlWriter.write(e, { writeChunk: function (t) { return _this.writeChunk(t); } }));
                        return [3, 3];
                    case 2:
                        _a = this.writeChunk(e);
                        _b.label = 3;
                    case 3: return [2, _a];
                }
            });
        });
    };
    class_3.prototype.flush = function () { this.dataOfRead.splice(0, this.dataOfRead.length); };
    return class_3;
}());
var w = S(U()), y = S(M());
var $ = 247, b = (function () {
    function class_4(e) {
        v(this, "options");
        v(this, "discoveredCallback");
        v(this, "connectedDevice");
        this.options = e, this.onBluetoothDeviceFound();
    }
    class_4.prototype.isDiscovery = function () {
        return __awaiter(this, void 0, void 0, function () { return __generator(this, function (_a) {
            switch (_a.label) {
                case 0: return [4, this.bluetoothAdapterState()];
                case 1: return [2, (_a.sent()).discovering || !1];
            }
        }); });
    };
    class_4.prototype.isConnected = function () { return this.connectedDevice ? this.connectedDevice.connectionState() === "CONNECTED" : !1; };
    class_4.prototype.bluetoothAdapterState = function () { return new Promise(function (e, t) { wx.getBluetoothAdapterState({ success: function (r) { return e(r); }, fail: function (r) { return t(r); } }); }); };
    class_4.prototype.connect = function (e, t) {
        return __awaiter(this, void 0, void 0, function () { var p, m, r, s, n, c, o; return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    if (!this.isConnected()) return [3, 2];
                    if (!((p = t == null ? void 0 : t.autoSwitchDevice) != null && p))
                        return [2, this.connectedDevice];
                    return [4, this.connectedDevice.disconnect()];
                case 1:
                    _a.sent();
                    _a.label = 2;
                case 2:
                    r = e.origin;
                    return [4, this.stopDiscovery().catch(function () { })];
                case 3:
                    _a.sent();
                    return [4, y.default.set(300)];
                case 4:
                    _a.sent();
                    return [4, this.createBLEConnectionWithRetry({ deviceId: r.deviceId, timeout: t == null ? void 0 : t.timeout })];
                case 5:
                    _a.sent();
                    return [4, y.default.set(500)];
                case 6:
                    _a.sent();
                    return [4, this.setBLEMTU(r.deviceId)];
                case 7:
                    s = _a.sent();
                    return [4, this.getBLEDeviceServices({ deviceId: r.deviceId })];
                case 8:
                    n = _a.sent();
                    return [4, this.findSCPair({ deviceId: r.deviceId, services: n })];
                case 9:
                    c = _a.sent();
                    if (!c)
                        return [2, Promise.reject("Can not get write characteristic by device: ".concat(e.name))];
                    o = (m = this.options) == null ? void 0 : m.flowControl;
                    o != null && o.enabled && s > 0 && (o = __assign(__assign({}, o), { initialMtu: s })), this.connectedDevice = new D({ device: r, scpair: c, flowControl: o });
                    return [4, this.stopDiscovery().catch(function () { })];
                case 10: return [2, (_a.sent(), Promise.resolve(this.connectedDevice))];
            }
        }); });
    };
    class_4.prototype.discovered = function (e) { this.discoveredCallback = e; };
    class_4.prototype.startDiscovery = function () {
        return __awaiter(this, void 0, void 0, function () { var e, _a, _b; return __generator(this, function (_c) {
            switch (_c.label) {
                case 0: return [4, this.requestLocation()];
                case 1:
                    _c.sent();
                    return [4, this.closeBluetoothAdapter()];
                case 2:
                    _c.sent();
                    return [4, y.default.set(300)];
                case 3:
                    _c.sent();
                    return [4, this.openBluetoothAdapter()];
                case 4:
                    _c.sent();
                    return [4, this.bluetoothAdapterState()];
                case 5:
                    e = _c.sent();
                    _a = e.available;
                    if (_a) return [3, 7];
                    return [4, y.default.set(500)];
                case 6:
                    _a = (_c.sent());
                    _c.label = 7;
                case 7:
                    _a;
                    _b = e.discovering;
                    if (!_b) return [3, 10];
                    return [4, this.stopDiscovery()];
                case 8:
                    _c.sent();
                    return [4, y.default.set(500)];
                case 9:
                    _b = (_c.sent());
                    _c.label = 10;
                case 10: return [2, (_b, new Promise(function (t, r) { wx.startBluetoothDevicesDiscovery({ allowDuplicatesKey: !1, interval: 0, success: function () { return t(); }, fail: function (s) { return r(s); } }); }))];
            }
        }); });
    };
    class_4.prototype.stopDiscovery = function () { return new Promise(function (e, t) { wx.stopBluetoothDevicesDiscovery({ success: function (r) { return e(r); }, fail: function (r) { return t(r); } }); }); };
    class_4.prototype.openBluetoothAdapter = function () {
        return __awaiter(this, void 0, void 0, function () { return __generator(this, function (_a) {
            return [2, new Promise(function (e, t) { wx.openBluetoothAdapter({ success: function (r) { if (r.errMsg && r.errMsg.indexOf("ok") == -1) {
                        t(r);
                        return;
                    } e(); }, fail: function (r) { return t(r); } }); })];
        }); });
    };
    class_4.prototype.closeBluetoothAdapter = function () {
        return __awaiter(this, void 0, void 0, function () { return __generator(this, function (_a) {
            return [2, new Promise(function (e, t) { wx.closeBluetoothAdapter({ success: function (r) { if (r.errMsg && r.errMsg.indexOf("ok") == -1) {
                        t(r);
                        return;
                    } e(); }, fail: function (r) { return t(r); } }); })];
        }); });
    };
    class_4.prototype.onBluetoothDeviceFound = function () {
        var _this = this;
        wx.onBluetoothDeviceFound(function (e) { return __awaiter(_this, void 0, void 0, function () {
            var t, r, _a;
            var _this = this;
            return __generator(this, function (_b) {
                switch (_b.label) {
                    case 0:
                        t = e.devices;
                        if (!t.length)
                            return [2];
                        r = t.filter(function (s) { var c, o; return s.name || s.localName ? !0 : (o = (c = _this.options) == null ? void 0 : c.allowNoName) != null ? o : !0; }).map(function (s) { var c = _this.extractMacFromAdvertisData(s.advertisData) || _this.formatMacAddress(s.deviceId); return new w.JluetoothDevice({ origin: s, name: s.name || s.localName || "Unknown", deviceId: s.deviceId, mac: c, rssi: s.RSSI, advertisData: s.advertisData }); });
                        _a = r.length && this.discoveredCallback;
                        if (!_a) return [3, 2];
                        return [4, this.discoveredCallback(r)];
                    case 1:
                        _a = (_b.sent());
                        _b.label = 2;
                    case 2:
                        _a;
                        return [2];
                }
            });
        }); });
    };
    class_4.prototype.extractMacFromAdvertisData = function (e) { if (!e || e.byteLength < 8)
        return null; var t = new Uint8Array(e); return Array.from(t.slice(2, 8)).map(function (s) { return s.toString(16).padStart(2, "0"); }).join(":").toUpperCase(); };
    class_4.prototype.formatMacAddress = function (e) { var t; return e.includes(":") ? e.toUpperCase() : e.length === 12 && ((t = e.match(/.{2}/g)) == null ? void 0 : t.join(":").toUpperCase()) || e; };
    class_4.prototype.createBLEConnection = function (e) {
        return __awaiter(this, void 0, void 0, function () { return __generator(this, function (_a) {
            return [2, new Promise(function (t, r) { wx.createBLEConnection({ deviceId: e.deviceId, timeout: e.timeout, success: function () { return t(); }, fail: function (s) { return r(s); } }); })];
        }); });
    };
    class_4.prototype.createBLEConnectionWithRetry = function (e) {
        return __awaiter(this, void 0, void 0, function () { var t, r, s_1; return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    r = 0;
                    _a.label = 1;
                case 1:
                    if (!(r < 3)) return [3, 8];
                    _a.label = 2;
                case 2:
                    _a.trys.push([2, 4, , 7]);
                    return [4, this.createBLEConnection(e)];
                case 3:
                    _a.sent();
                    return [2];
                case 4:
                    s_1 = _a.sent();
                    if (t = s_1, r === 2)
                        throw s_1;
                    console.log("[BLE] createBLEConnection failed, retry ".concat(r + 1, "/2"), s_1);
                    return [4, this.closeBLEConnection(e.deviceId)];
                case 5:
                    _a.sent();
                    return [4, y.default.set(500)];
                case 6:
                    _a.sent();
                    return [3, 7];
                case 7:
                    r += 1;
                    return [3, 1];
                case 8: throw t;
            }
        }); });
    };
    class_4.prototype.closeBLEConnection = function (e) {
        return __awaiter(this, void 0, void 0, function () { return __generator(this, function (_a) {
            switch (_a.label) {
                case 0: return [4, new Promise(function (t) { wx.closeBLEConnection({ deviceId: e, success: function () { return t(); }, fail: function () { return t(); } }); })];
                case 1:
                    _a.sent();
                    return [2];
            }
        }); });
    };
    class_4.prototype.setBLEMTU = function (e) {
        return __awaiter(this, void 0, void 0, function () { return __generator(this, function (_a) {
            try {
                if (String(wx.getSystemInfoSync().platform).toLowerCase() !== "android")
                    return [2, 0];
            }
            catch (t) {
                return [2, 0];
            }
            return [2, typeof wx.setBLEMTU != "function" ? 0 : new Promise(function (t) { wx.setBLEMTU({ deviceId: e, mtu: $, success: function () { return t($); }, fail: function (r) { console.warn("[BLE] setBLEMTU failed; using default MTU", r), t(0); } }); })];
        }); });
    };
    class_4.prototype.getBLEDeviceServices = function (e) {
        return __awaiter(this, void 0, void 0, function () { return __generator(this, function (_a) {
            return [2, new Promise(function (t, r) { wx.getBLEDeviceServices({ deviceId: e.deviceId, success: function (s) { if (s.errMsg.indexOf("ok") == -1) {
                        r(s.errMsg);
                        return;
                    } t(s.services); }, fail: function (s) { return r(s); } }); })];
        }); });
    };
    class_4.prototype.getBLEDeviceCharacteristics = function (e) {
        return __awaiter(this, void 0, void 0, function () { return __generator(this, function (_a) {
            return [2, new Promise(function (t, r) { wx.getBLEDeviceCharacteristics({ deviceId: e.deviceId, serviceId: e.serviceId, success: function (s) { if (s.errMsg.indexOf("ok") == -1) {
                        r(s.errMsg);
                        return;
                    } t(s.characteristics); }, fail: function (s) { return r(s); } }); })];
        }); });
    };
    class_4.prototype.requestLocation = function () {
        return __awaiter(this, void 0, void 0, function () { return __generator(this, function (_a) {
            return [2, new Promise(function (e, t) { wx.getLocation({ success: function () { return e(); }, fail: function (r) { return t(r); } }); })];
        }); });
    };
    class_4.prototype.findSCPair = function (e) {
        return __awaiter(this, void 0, void 0, function () {
            var r, s, n, c, o, p, m, W, N, k, F, R, t, _i, _a, a, h, _b, _c, a, h, l, f, _d, h_1, d, _e, h_2, d, _f, _g, a, l, _h, _j, a, h, l, f, _k, _l, a, l;
            var _this = this;
            return __generator(this, function (_m) {
                switch (_m.label) {
                    case 0:
                        t = new Map;
                        _i = 0, _a = e.services;
                        _m.label = 1;
                    case 1:
                        if (!(_i < _a.length)) return [3, 4];
                        a = _a[_i];
                        return [4, this.getBLEDeviceCharacteristics({ deviceId: e.deviceId, serviceId: a.uuid })];
                    case 2:
                        h = _m.sent();
                        t.set(a.uuid, h);
                        _m.label = 3;
                    case 3:
                        _i++;
                        return [3, 1];
                    case 4:
                        if ((s = (r = this.options) == null ? void 0 : r.flowControl) != null && s.enabled)
                            return [2, (0, w.findBleFlowControlCharacteristics)({ services: e.services, flowControlOptions: this.options.flowControl, isServiceAllowed: function (a) { var h; return w.TBluetoothHelpers.isAllowServices(a.uuid, (h = _this.options) == null ? void 0 : h.allowServices); }, getServiceUuid: function (a) { return a.uuid; }, getCharacteristics: function (a) { return t.get(a.uuid); }, getCharacteristicUuid: function (a) { return a.uuid; } })];
                        if ((n = this.options) != null && n.allowedWriteCharacteristic && ((c = this.options) != null && c.allowedReadCharacteristic))
                            for (_b = 0, _c = e.services; _b < _c.length; _b++) {
                                a = _c[_b];
                                if (!w.TBluetoothHelpers.isAllowServices(a.uuid, (o = this.options) == null ? void 0 : o.allowServices))
                                    continue;
                                h = t.get(a.uuid), l = null, f = null;
                                for (_d = 0, h_1 = h; _d < h_1.length; _d++) {
                                    d = h_1[_d];
                                    ((p = this.options) == null ? void 0 : p.allowedWriteCharacteristic.toLowerCase()) == d.uuid.toLowerCase() && (l = d);
                                }
                                for (_e = 0, h_2 = h; _e < h_2.length; _e++) {
                                    d = h_2[_e];
                                    ((m = this.options) == null ? void 0 : m.allowedReadCharacteristic.toLowerCase()) == d.uuid.toLowerCase() && (f = d);
                                }
                                if (l != null && f != null)
                                    return [2, { service: a, write: l, read: f }];
                            }
                        for (_f = 0, _g = e.services; _f < _g.length; _f++) {
                            a = _g[_f];
                            if (!w.TBluetoothHelpers.isAllowServices(a.uuid, (W = this.options) == null ? void 0 : W.allowServices))
                                continue;
                            l = t.get(a.uuid).find(function (f) { var d = f.properties; return d.write && d.notify; });
                            if (l)
                                return [2, { service: a, write: l, read: l }];
                        }
                        if ((k = (N = this.options) == null ? void 0 : N.allowDetectDifferentCharacteristic) == null || k)
                            for (_h = 0, _j = e.services; _h < _j.length; _h++) {
                                a = _j[_h];
                                if (!w.TBluetoothHelpers.isAllowServices(a.uuid, (F = this.options) == null ? void 0 : F.allowServices))
                                    continue;
                                h = t.get(a.uuid), l = h.find(function (d) { return d.properties.write; }), f = h.find(function (d) { return d.properties.notify; });
                                if (l && f)
                                    return [2, { service: a, write: l, read: f }];
                            }
                        else
                            for (_k = 0, _l = e.services; _k < _l.length; _k++) {
                                a = _l[_k];
                                if (!w.TBluetoothHelpers.isAllowServices(a.uuid, (R = this.options) == null ? void 0 : R.allowServices))
                                    continue;
                                l = t.get(a.uuid).find(function (f) { return f.properties.write; });
                                if (l)
                                    return [2, { service: a, write: l }];
                            }
                        return [2];
                }
            });
        });
    };
    return class_4;
}());

}, function(modId) {var map = {}; return __REQUIRE__(map[modId], modId); })
return __REQUIRE__(1790237021547);
})()
//miniprogram-npm-outsideDeps=[]
//# sourceMappingURL=index.js.map