module.exports = (function() {
var __MODS__ = {};
var __DEFINE__ = function(modId, func, req) { var m = { exports: {}, _tempexports: {} }; __MODS__[modId] = { status: 0, func: func, req: req, m: m }; };
var __REQUIRE__ = function(modId, source) { if(!__MODS__[modId]) return require(source); if(!__MODS__[modId].status) { var m = __MODS__[modId].m; m._exports = m._tempexports; var desp = Object.getOwnPropertyDescriptor(m, "exports"); if (desp && desp.configurable) Object.defineProperty(m, "exports", { set: function (val) { if(typeof val === "object" && val !== m._exports) { m._exports.__proto__ = val.__proto__; Object.keys(val).forEach(function (k) { m._exports[k] = val[k]; }); } m._tempexports = val }, get: function () { return m._tempexports; } }); __MODS__[modId].status = 1; __MODS__[modId].func(__MODS__[modId].req, m, m.exports); } return __MODS__[modId].m.exports; };
var __REQUIRE_WILDCARD__ = function(obj) { if(obj && obj.__esModule) { return obj; } else { var newObj = {}; if(obj != null) { for(var k in obj) { if (Object.prototype.hasOwnProperty.call(obj, k)) newObj[k] = obj[k]; } } newObj.default = obj; return newObj; } };
var __REQUIRE_DEFAULT__ = function(obj) { return obj && obj.__esModule ? obj.default : obj; };
__DEFINE__(1681364781936, function(require, module, exports) {

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
__exportStar(require("./connected"), exports);
__exportStar(require("./provider"), exports);

}, function(modId) {var map = {"./connected":1681364781937,"./provider":1681364781938}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364781937, function(require, module, exports) {

var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.WechatBleConnectedDevice = void 0;
const frame_father_1 = require("@psdk/frame-father");
const await_timeout_1 = __importDefault(require("await-timeout"));
class WechatBleConnectedDevice {
    constructor(options) {
        this.device = options.device;
        this.scpair = options.scpair;
        this._connectionState = frame_father_1.ConnectionState.CONNECTED;
        this.dataOfRead = [];
        this.doListen();
    }
    doListen() {
        wx.onBLECharacteristicValueChange(value => {
            this.dataOfRead.push(value);
        });
        wx.onBLEConnectionStateChange(value => {
            this._connectionState = value.connected ? frame_father_1.ConnectionState.CONNECTED : frame_father_1.ConnectionState.DISCONNECTED;
        });
        // wx.notifyBLECharacteristicValueChange({
        //   deviceId: this.device.deviceId,
        //   serviceId: this.readPair.service.uuid,
        //   characteristicId: this.readPair.characteristic.uuid,
        //   state: true,
        //   success: result => console.log(result),
        //   // @ts-ignore
        //   fail: (e) => console.error(e),
        // });
    }
    realRead() {
        return __awaiter(this, void 0, void 0, function* () {
            return new Promise((resolve, reject) => {
                if (this.scpair.read == null) {
                    reject(`the connect device not support read operation: service id: [${this.scpair.service.uuid}]`);
                    return;
                }
                wx.readBLECharacteristicValue({
                    deviceId: this.device.deviceId,
                    serviceId: this.scpair.service.uuid,
                    characteristicId: this.scpair.read.uuid,
                    success: result => {
                        if (result.errMsg.indexOf('ok') == -1) {
                            reject(result.errMsg);
                            return;
                        }
                        resolve();
                    },
                    // @ts-ignore
                    fail: (e) => reject(e),
                });
            });
        });
    }
    connectionState() {
        return this._connectionState;
    }
    deviceName() {
        return this.device.localName || this.device.name || 'NONE';
    }
    disconnect() {
        return __awaiter(this, void 0, void 0, function* () {
            return new Promise((resolve, reject) => {
                wx.closeBLEConnection({
                    deviceId: this.device.deviceId,
                    success: () => {
                        this.device = null;
                        this.scpair = null;
                        resolve();
                    },
                    // @ts-ignore
                    fail: (e) => reject(e),
                });
            });
        });
    }
    canRead() {
        return this.scpair.read != null;
    }
    read(options) {
        var _a;
        return __awaiter(this, void 0, void 0, function* () {
            if (this.dataOfRead.length > 0) {
                this.dataOfRead.splice(0, this.dataOfRead.length);
            }
            yield this.realRead();
            const timeout = ((_a = options === null || options === void 0 ? void 0 : options.timeout) !== null && _a !== void 0 ? _a : 5000);
            const startTime = +new Date();
            while (true) {
                const now = +new Date();
                if (now - startTime > timeout) {
                    return new Uint8Array([]);
                }
                if (this.dataOfRead.length == 0) {
                    yield await_timeout_1.default.set(100);
                    continue;
                }
                const data = this.dataOfRead.pop();
                const value = data.value;
                return new Uint8Array(value);
            }
        });
    }
    write(data) {
        return __awaiter(this, void 0, void 0, function* () {
            return new Promise((resolve, reject) => {
                wx.writeBLECharacteristicValue({
                    deviceId: this.device.deviceId,
                    serviceId: this.scpair.service.uuid,
                    characteristicId: this.scpair.write.uuid,
                    // @ts-ignore
                    value: data.buffer,
                    success: result => {
                        if (result.errMsg.indexOf('ok') == -1) {
                            reject(result.errMsg);
                            return;
                        }
                        resolve();
                    },
                    // @ts-ignore
                    fail: (e) => reject(e)
                });
            });
        });
    }
    flush() {
        this.dataOfRead.splice(0, this.dataOfRead.length);
    }
}
exports.WechatBleConnectedDevice = WechatBleConnectedDevice;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364781938, function(require, module, exports) {

var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.WechatBleBluetooth = void 0;
const device_bluetooth_traits_1 = require("@psdk/device-bluetooth-traits");
const frame_father_1 = require("@psdk/frame-father");
const await_timeout_1 = __importDefault(require("await-timeout"));
const connected_1 = require("./connected");
class WechatBleBluetooth extends device_bluetooth_traits_1.Jluetooth {
    constructor(options) {
        super();
        this.options = options;
        this.onBluetoothDeviceFound();
    }
    isConnected() {
        if (!this.connectedDevice)
            return false;
        return this.connectedDevice.connectionState() === frame_father_1.ConnectionState.CONNECTED;
    }
    bluetoothAdapterState() {
        return new Promise((resolve, reject) => {
            wx.getBluetoothAdapterState({
                success: (r) => resolve(r),
                // @ts-ignore
                fail: (e) => reject(e)
            });
        });
    }
    connect(device, options) {
        var _a;
        return __awaiter(this, void 0, void 0, function* () {
            if (this.isConnected()) {
                if (!((_a = options === null || options === void 0 ? void 0 : options.autoSwitchDevice) !== null && _a !== void 0 ? _a : false)) {
                    return this.connectedDevice;
                }
                yield this.connectedDevice.disconnect();
            }
            const origin = device.origin;
            yield this.createBLEConnection({ deviceId: origin.deviceId, timeout: options === null || options === void 0 ? void 0 : options.timeout, });
            yield await_timeout_1.default.set(500);
            const services = yield this.getBLEDeviceServices({ deviceId: origin.deviceId });
            const scpair = yield this.findSCPair({
                deviceId: origin.deviceId,
                services,
            });
            if (!scpair) {
                return Promise.reject(`Can not get write characteristic by device: ${device.name}`);
            }
            this.connectedDevice = new connected_1.WechatBleConnectedDevice({
                device: origin,
                scpair,
            });
            yield this.stopDiscovery();
            return Promise.resolve(this.connectedDevice);
        });
    }
    discovered(callback) {
        this.discoveredCallback = callback;
    }
    startDiscovery() {
        return __awaiter(this, void 0, void 0, function* () {
            yield this.requestLocation();
            yield this.closeBluetoothAdapter();
            yield await_timeout_1.default.set(300);
            yield this.openBluetoothAdapter();
            const state = yield this.bluetoothAdapterState();
            if (!state.available) {
                yield await_timeout_1.default.set(500);
            }
            if (state.discovering) {
                yield this.stopDiscovery();
                yield await_timeout_1.default.set(500);
            }
            return new Promise((resolve, reject) => {
                wx.startBluetoothDevicesDiscovery({
                    // services: this.allowServices,
                    allowDuplicatesKey: false,
                    interval: 0,
                    success: () => resolve(),
                    // @ts-ignore
                    fail: (e) => reject(e),
                    // complete: () => resolve(),
                });
            });
        });
    }
    stopDiscovery() {
        return new Promise((resolve, reject) => {
            wx.stopBluetoothDevicesDiscovery({
                success: (result) => resolve(result),
                // @ts-ignore
                fail: (e) => reject(e),
            });
        });
    }
    // ### inner function
    openBluetoothAdapter() {
        return __awaiter(this, void 0, void 0, function* () {
            return new Promise((resolve, reject) => {
                wx.openBluetoothAdapter({
                    // @ts-ignore
                    success: (ret) => {
                        if (ret.errMsg && ret.errMsg.indexOf('ok') == -1) {
                            reject(ret);
                            return;
                        }
                        resolve();
                    },
                    // @ts-ignore
                    fail: (e) => reject(e)
                });
            });
        });
    }
    closeBluetoothAdapter() {
        return __awaiter(this, void 0, void 0, function* () {
            return new Promise((resolve, reject) => {
                wx.closeBluetoothAdapter({
                    // @ts-ignore
                    success: (ret) => {
                        if (ret.errMsg && ret.errMsg.indexOf('ok') == -1) {
                            reject(ret);
                            return;
                        }
                        resolve();
                    },
                    // @ts-ignore
                    fail: (e) => reject(e)
                });
            });
        });
    }
    onBluetoothDeviceFound() {
        wx.onBluetoothDeviceFound((result) => __awaiter(this, void 0, void 0, function* () {
            const foundDevices = result.devices;
            if (!foundDevices.length) {
                return;
            }
            const devices = foundDevices
                .filter(item => {
                var _a, _b;
                const name = item.name || item.localName;
                if (name)
                    return true;
                return (_b = (_a = this.options) === null || _a === void 0 ? void 0 : _a.allowNoName) !== null && _b !== void 0 ? _b : true;
            })
                .map(item => new device_bluetooth_traits_1.JluetoothDevice({
                origin: item,
                name: item.name || item.localName,
                deviceId: item.deviceId,
            }));
            if (!devices.length) {
                return;
            }
            if (this.discoveredCallback) {
                yield this.discoveredCallback(devices);
            }
        }));
    }
    createBLEConnection(options) {
        return __awaiter(this, void 0, void 0, function* () {
            return new Promise((resolve, reject) => {
                wx.createBLEConnection({
                    deviceId: options.deviceId,
                    timeout: options.timeout,
                    success: () => resolve(),
                    // @ts-ignore
                    fail: (e) => reject(e),
                });
            });
        });
    }
    getBLEDeviceServices(options) {
        return __awaiter(this, void 0, void 0, function* () {
            return new Promise((resolve, reject) => {
                wx.getBLEDeviceServices({
                    deviceId: options.deviceId,
                    success: (result) => {
                        if (result.errMsg.indexOf('ok') == -1) {
                            reject(result.errMsg);
                            return;
                        }
                        resolve(result.services);
                    },
                    // @ts-ignore
                    fail: (e) => reject(e),
                });
            });
        });
    }
    getBLEDeviceCharacteristics(options) {
        return __awaiter(this, void 0, void 0, function* () {
            return new Promise((resolve, reject) => {
                wx.getBLEDeviceCharacteristics({
                    deviceId: options.deviceId,
                    serviceId: options.serviceId,
                    success: (result) => {
                        if (result.errMsg.indexOf('ok') == -1) {
                            reject(result.errMsg);
                            return;
                        }
                        resolve(result.characteristics);
                    },
                    // @ts-ignore
                    fail: (e) => reject(e),
                });
            });
        });
    }
    requestLocation() {
        return __awaiter(this, void 0, void 0, function* () {
            return new Promise((resolve, reject) => {
                // wx.authorize({
                //   scope: 'scope.userLocation',
                //   success: () => resolve(),
                //   // @ts-ignore
                //   fail: (e) => reject(e),
                // });
                wx.getLocation({
                    success: () => resolve(),
                    // @ts-ignore
                    fail: (e) => reject(e),
                });
            });
        });
    }
    findSCPair(options) {
        var _a, _b, _c, _d, _e, _f, _g, _h;
        return __awaiter(this, void 0, void 0, function* () {
            // fill data
            const _characteristicsMap = new Map();
            for (const service of options.services) {
                const characteristics = yield this.getBLEDeviceCharacteristics({
                    deviceId: options.deviceId,
                    serviceId: service.uuid,
                });
                _characteristicsMap.set(service.uuid, characteristics);
            }
            // use special first
            if ((_a = this.options) === null || _a === void 0 ? void 0 : _a.allowCharacteristic) {
                for (const service of options.services) {
                    if (!device_bluetooth_traits_1.TBluetoothHelpers.isAllowServices(service.uuid, (_b = this.options) === null || _b === void 0 ? void 0 : _b.allowServices)) {
                        continue;
                    }
                    const characteristics = _characteristicsMap.get(service.uuid);
                    for (const characteristic of characteristics) {
                        if (((_c = this.options) === null || _c === void 0 ? void 0 : _c.allowCharacteristic) != characteristic.uuid)
                            continue;
                        const properties = characteristic.properties;
                        return {
                            service,
                            write: characteristic,
                            read: properties.read ? characteristic : null,
                        };
                    }
                }
            }
            // choose best characteristic
            for (const service of options.services) {
                if (!device_bluetooth_traits_1.TBluetoothHelpers.isAllowServices(service.uuid, (_d = this.options) === null || _d === void 0 ? void 0 : _d.allowServices)) {
                    continue;
                }
                const characteristics = _characteristicsMap.get(service.uuid);
                // let readCharacteristic: GetBLEDeviceCharacteristicsSuccessData;
                // let writeCharacteristic: GetBLEDeviceCharacteristicsSuccessData;
                const pickedCharacteristic = characteristics.find(characteristic => {
                    const properties = characteristic.properties;
                    // @ts-ignore
                    return (properties.writeNoResponse || properties.write) && (properties.read);
                });
                if (pickedCharacteristic) {
                    return {
                        service,
                        write: pickedCharacteristic,
                        read: pickedCharacteristic,
                    };
                }
            }
            if ((_f = (_e = this.options) === null || _e === void 0 ? void 0 : _e.allowDetectDifferentCharacteristic) !== null && _f !== void 0 ? _f : false) {
                // choose different characteristic with write and read properties
                for (const service of options.services) {
                    if (!device_bluetooth_traits_1.TBluetoothHelpers.isAllowServices(service.uuid, (_g = this.options) === null || _g === void 0 ? void 0 : _g.allowServices)) {
                        continue;
                    }
                    const characteristics = _characteristicsMap.get(service.uuid);
                    const writeCharacteristic = characteristics.find(characteristic => {
                        const properties = characteristic.properties;
                        // @ts-ignore
                        return (properties.writeNoResponse || properties.write);
                    });
                    const readCharacteristic = characteristics.find(characteristic => {
                        const properties = characteristic.properties;
                        return (properties.read);
                    });
                    if (writeCharacteristic && readCharacteristic) {
                        return {
                            service,
                            write: writeCharacteristic,
                            read: readCharacteristic,
                        };
                    }
                }
            }
            else {
                // only write
                for (const service of options.services) {
                    if (!device_bluetooth_traits_1.TBluetoothHelpers.isAllowServices(service.uuid, (_h = this.options) === null || _h === void 0 ? void 0 : _h.allowServices)) {
                        continue;
                    }
                    const characteristics = _characteristicsMap.get(service.uuid);
                    const writeCharacteristic = characteristics.find(characteristic => {
                        const properties = characteristic.properties;
                        // @ts-ignore
                        return (properties.writeNoResponse || properties.write);
                    });
                    if (writeCharacteristic) {
                        return {
                            service,
                            write: writeCharacteristic,
                        };
                    }
                }
            }
        });
    }
}
exports.WechatBleBluetooth = WechatBleBluetooth;

}, function(modId) { var map = {"./connected":1681364781937}; return __REQUIRE__(map[modId], modId); })
return __REQUIRE__(1681364781936);
})()
//miniprogram-npm-outsideDeps=["@psdk/frame-father","await-timeout","@psdk/device-bluetooth-traits"]
//# sourceMappingURL=index.js.map