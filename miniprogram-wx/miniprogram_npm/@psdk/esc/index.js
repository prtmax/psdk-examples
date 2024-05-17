module.exports = (function() {
var __MODS__ = {};
var __DEFINE__ = function(modId, func, req) { var m = { exports: {}, _tempexports: {} }; __MODS__[modId] = { status: 0, func: func, req: req, m: m }; };
var __REQUIRE__ = function(modId, source) { if(!__MODS__[modId]) return require(source); if(!__MODS__[modId].status) { var m = __MODS__[modId].m; m._exports = m._tempexports; var desp = Object.getOwnPropertyDescriptor(m, "exports"); if (desp && desp.configurable) Object.defineProperty(m, "exports", { set: function (val) { if(typeof val === "object" && val !== m._exports) { m._exports.__proto__ = val.__proto__; Object.keys(val).forEach(function (k) { m._exports[k] = val[k]; }); } m._tempexports = val }, get: function () { return m._tempexports; } }); __MODS__[modId].status = 1; __MODS__[modId].func(__MODS__[modId].req, m, m.exports); } return __MODS__[modId].m.exports; };
var __REQUIRE_WILDCARD__ = function(obj) { if(obj && obj.__esModule) { return obj; } else { var newObj = {}; if(obj != null) { for(var k in obj) { if (Object.prototype.hasOwnProperty.call(obj, k)) newObj[k] = obj[k]; } } newObj.default = obj; return newObj; } };
var __REQUIRE_DEFAULT__ = function(obj) { return obj && obj.__esModule ? obj.default : obj; };
__DEFINE__(1715917493987, function(require, module, exports) {

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
__exportStar(require("./impls"), exports);
__exportStar(require("./args"), exports);

}, function(modId) {var map = {"./impls":1715917493988,"./args":1715917493991}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917493988, function(require, module, exports) {

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
__exportStar(require("./generic"), exports);
__exportStar(require("./esc"), exports);

}, function(modId) { var map = {"./generic":1715917493989,"./esc":1715917494020}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917493989, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.GenericESC = void 0;
const basic_1 = require("./basic");
class GenericESC extends basic_1.BasicESC {
    constructor(lifecycle) {
        super(lifecycle);
    }
}
exports.GenericESC = GenericESC;

}, function(modId) { var map = {"./basic":1715917493990}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917493990, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.BasicESC = void 0;
const frame_father_1 = require("@psdk/frame-father");
const args_1 = require("../args");
const types_1 = require("../types");
class BasicESC extends frame_father_1.PSDK {
    constructor(lifecycle) {
        super();
        this._lifecycle = lifecycle;
        this._commander = frame_father_1.Commander.make();
    }
    connectedDevice() {
        return this._lifecycle.connectedDevice;
    }
    commander() {
        return this._commander;
    }
    /**
     * 走纸命令
     * @param arg
     */
    lineDot(arg) {
        return super.push(new args_1.ELineDot({ dot: arg }));
    }
    /**
     * 回纸命令
     * @return
     * @param arg
     */
    backLineDot(arg) {
        return super.push(new args_1.EBackLineDot({ dot: arg }));
    }
    /**
     * 查询电量
     */
    batteryVolume() {
        return super.push(new args_1.EBatteryVolume());
    }
    /**
     * 使能打印机
     */
    enable() {
        return super.push(new args_1.EEnable());
    }
    /**
     * 获取关机时间
     */
    getShutdownTime() {
        return super.push(new args_1.EGetShutdownTime());
    }
    /**
     * 打印图片
     */
    image(arg) {
        return super.push(arg);
    }
    /**
     *学习缝隙
     */
    learnLabelGap() {
        return super.push(new args_1.ELearnLabelGap());
    }
    /**
     *画线
     */
    line(arg) {
        return super.push(arg);
    }
    /**
     * 设置打印起始横向位置
     * @param arg 0:居左 1:居中 2:居右
     */
    location(arg) {
        return super.push(new args_1.ELocation({ location: arg }));
    }
    /**
     *查询MAC
     */
    mac() {
        return super.push(new args_1.EMac());
    }
    /**
     * 查询打印机所有信息
     */
    info() {
        return super.push(new args_1.EInfo());
    }
    /**
     *查询打印机型号
     */
    model() {
        return super.push(new args_1.EModel());
    }
    /**
     *查询蓝牙名称
     */
    name() {
        return super.push(new args_1.EName());
    }
    /**
     *纸张类型
     */
    paperType(arg) {
        return super.push(arg !== null && arg !== void 0 ? arg : new args_1.EPaperType({ paperType: types_1.PaperType.FOLDED_BLACK_LABEL_PAPER }));
    }
    /**
     * 打印定位
     */
    position() {
        return super.push(new args_1.EPosition());
    }
    /**
     * 查询打印机固件版本
     */
    printerVersion() {
        return super.push(new args_1.EPrinterVersion());
    }
    /**
     * 设置关机时间
     */
    setShutdownTime(arg) {
        return super.push(new args_1.ESetShutdownTime({ time: arg }));
    }
    /**
     *查询SN
     */
    sn() {
        return super.push(new args_1.ESN());
    }
    /**
     *查询打印机状态
     */
    state() {
        return super.push(new args_1.EState());
    }
    /**
     *结束打印任务
     */
    stopJob() {
        return super.push(new args_1.EStopJob());
    }
    /**
     * 设置打印机浓度(0-2)
     * @param arg 0:低浓度 1:中浓度 2:高浓度
     */
    thickness(arg) {
        return super.push(new args_1.EThickness({ thickness: arg }));
    }
    /**
     *查询蓝牙固件版本
     */
    version() {
        return super.push(new args_1.EVersion());
    }
    /**
     *唤醒打印机
     */
    wakeup() {
        return super.push(new args_1.EWakeup());
    }
    /**
     * 设置蓝牙类型(支持压缩的机器需要调用)
     */
    setBTType() {
        return super.push(new args_1.EBTType());
    }
}
exports.BasicESC = BasicESC;

}, function(modId) { var map = {"../args":1715917493991,"../types":1715917493998}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917493991, function(require, module, exports) {

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
__exportStar(require("./backlinedot"), exports);
__exportStar(require("./basic"), exports);
__exportStar(require("./batteryvolume"), exports);
__exportStar(require("./enable"), exports);
__exportStar(require("./getshutdowntime"), exports);
__exportStar(require("./image"), exports);
__exportStar(require("./learnlabelgap"), exports);
__exportStar(require("./line"), exports);
__exportStar(require("./linedot"), exports);
__exportStar(require("./location"), exports);
__exportStar(require("./mac"), exports);
__exportStar(require("./model"), exports);
__exportStar(require("./name"), exports);
__exportStar(require("./papertype"), exports);
__exportStar(require("./position"), exports);
__exportStar(require("./printerversion"), exports);
__exportStar(require("./setshutdowntime"), exports);
__exportStar(require("./sn"), exports);
__exportStar(require("./state"), exports);
__exportStar(require("./stopjob"), exports);
__exportStar(require("./thickness"), exports);
__exportStar(require("./version"), exports);
__exportStar(require("./wakeup"), exports);
__exportStar(require("./info"), exports);
__exportStar(require("./bttype"), exports);

}, function(modId) { var map = {"./backlinedot":1715917493992,"./basic":1715917493993,"./batteryvolume":1715917493994,"./enable":1715917493995,"./getshutdowntime":1715917493996,"./image":1715917493997,"./learnlabelgap":1715917494001,"./line":1715917494002,"./linedot":1715917494003,"./location":1715917494004,"./mac":1715917494005,"./model":1715917494006,"./name":1715917494007,"./papertype":1715917494008,"./position":1715917494009,"./printerversion":1715917494010,"./setshutdowntime":1715917494011,"./sn":1715917494012,"./state":1715917494013,"./stopjob":1715917494014,"./thickness":1715917494015,"./version":1715917494016,"./wakeup":1715917494017,"./info":1715917494018,"./bttype":1715917494019}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917493992, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EBackLineDot = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
/**
 * BackLineDot
 */
class EBackLineDot extends basic_1.BasicESCArg {
    constructor(options) {
        var _a;
        super();
        this.dot = (_a = options.dot) !== null && _a !== void 0 ? _a : 0;
    }
    clause() {
        return frame_father_1.BinaryCommand.with(this.header())
            .appendNumber(this.dot).clause();
    }
    header() {
        return new Uint8Array([0x10, 0xFF, 0x81]);
    }
}
exports.EBackLineDot = EBackLineDot;

}, function(modId) { var map = {"./basic":1715917493993}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917493993, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.BasicESCArg = void 0;
const frame_father_1 = require("@psdk/frame-father");
class BasicESCArg extends frame_father_1.EasyArg {
    append(arg) {
        super.append(arg);
        return this;
    }
    prepend(arg) {
        super.prepend(arg);
        return this;
    }
    newline() {
        return false;
    }
}
exports.BasicESCArg = BasicESCArg;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917493994, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EBatteryVolume = void 0;
const frame_father_1 = require("@psdk/frame-father");
class EBatteryVolume extends frame_father_1.OnlyBinaryHeaderArg {
    header() {
        return new Uint8Array([0x10, 0xFF, 0x50, 0xF1]);
    }
}
exports.EBatteryVolume = EBatteryVolume;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917493995, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EEnable = void 0;
const frame_father_1 = require("@psdk/frame-father");
class EEnable extends frame_father_1.OnlyBinaryHeaderArg {
    header() {
        return new Uint8Array([0x10, 0xFF, 0xFE, 0x01]);
    }
}
exports.EEnable = EEnable;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917493996, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EGetShutdownTime = void 0;
const frame_father_1 = require("@psdk/frame-father");
class EGetShutdownTime extends frame_father_1.OnlyBinaryHeaderArg {
    header() {
        return new Uint8Array([0x10, 0xFF, 0x13]);
    }
}
exports.EGetShutdownTime = EGetShutdownTime;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917493997, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EImage = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
const types_1 = require("../types");
const frame_imageb_1 = require("@psdk/frame-imageb");
/**
 * Image
 */
class EImage extends basic_1.BasicESCArg {
    constructor(options) {
        var _a, _b, _c, _d;
        super();
        this.compress = (_a = options.compress) !== null && _a !== void 0 ? _a : false;
        this.reverse = (_b = options.reverse) !== null && _b !== void 0 ? _b : false;
        this.threshold = (_c = options.threshold) !== null && _c !== void 0 ? _c : 190;
        this.mode = (_d = options.mode) !== null && _d !== void 0 ? _d : types_1.EImageMode.NORMAL;
        this.image = options.image;
    }
    clause() {
        const processer = new frame_imageb_1.Pbita({
            command: 'esc',
            threshold: this.threshold,
            compress: this.compress,
            reverse: this.reverse,
        });
        const info = processer.process(this.image);
        const fimage = info.result.data;
        const fbytes = info.result.bytes;
        if (fimage == null) {
            throw new Error('Wrong image data');
        }
        let width = fimage.width;
        let height = fimage.height;
        const eWidth = Math.floor((width % 8 === 0) ? (width / 8) : (width / 8 + 1));
        if (this.compress) {
            return frame_father_1.BinaryCommand.with(this.header())
                .appendNumber(eWidth / 256)
                .appendNumber(eWidth % 256)
                .appendNumber(height / 256)
                .appendNumber(height % 256)
                .appendNumber((fbytes.length - 2) >> 24 & 0xff)
                .appendNumber((fbytes.length - 2) >> 16 & 0xff)
                .appendNumber((fbytes.length - 2) >> 8 & 0xff)
                .appendNumber((fbytes.length - 2) & 0xff)
                .appendU8A(fbytes.subarray(2, fbytes.length))
                .clause();
        }
        return frame_father_1.BinaryCommand.with(this.header())
            .appendNumber(this.mode)
            .appendNumber(eWidth % 256)
            .appendNumber(eWidth / 256)
            .appendNumber(height % 256)
            .appendNumber(height / 256)
            .appendU8A(fbytes)
            .clause();
    }
    header() {
        return new Uint8Array(this.compress ? [0x1F, 0x00] : [0x1D, 0x76, 0x30]);
    }
}
exports.EImage = EImage;

}, function(modId) { var map = {"./basic":1715917493993,"../types":1715917493998}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917493998, function(require, module, exports) {

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
__exportStar(require("./image"), exports);
__exportStar(require("./papertype"), exports);

}, function(modId) { var map = {"./image":1715917493999,"./papertype":1715917494000}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917493999, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EImageMode = void 0;
var EImageMode;
(function (EImageMode) {
    EImageMode[EImageMode["NORMAL"] = 0] = "NORMAL";
    EImageMode[EImageMode["DOUBLE_WIDTH"] = 1] = "DOUBLE_WIDTH";
    EImageMode[EImageMode["DOUBLE_HEIGHT"] = 2] = "DOUBLE_HEIGHT";
    EImageMode[EImageMode["DOUBLE_WIDTH_HEIGHT"] = 3] = "DOUBLE_WIDTH_HEIGHT";
})(EImageMode = exports.EImageMode || (exports.EImageMode = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494000, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.PaperType = void 0;
var PaperType;
(function (PaperType) {
    /**
     * 折叠黑标纸
     */
    PaperType[PaperType["FOLDED_BLACK_LABEL_PAPER"] = 0] = "FOLDED_BLACK_LABEL_PAPER";
    /**
     * 连续卷筒纸
     */
    PaperType[PaperType["CONTINUOUS_REEL_PAPER"] = 1] = "CONTINUOUS_REEL_PAPER";
    /**
     * 不干胶缝隙纸
     */
    PaperType[PaperType["NO_DRY_ADHESIVE_PAPER"] = 2] = "NO_DRY_ADHESIVE_PAPER";
})(PaperType = exports.PaperType || (exports.PaperType = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494001, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.ELearnLabelGap = void 0;
const frame_father_1 = require("@psdk/frame-father");
class ELearnLabelGap extends frame_father_1.OnlyBinaryHeaderArg {
    header() {
        return new Uint8Array([0x10, 0xFF, 0x03]);
    }
}
exports.ELearnLabelGap = ELearnLabelGap;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494002, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.ELine = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
/**
 * Line
 */
class ELine extends basic_1.BasicESCArg {
    constructor(options) {
        var _a, _b;
        super();
        this.x = (_a = options.x) !== null && _a !== void 0 ? _a : 0;
        this.y = (_b = options.y) !== null && _b !== void 0 ? _b : 0;
    }
    clause() {
        return frame_father_1.BinaryCommand.with(this.header())
            .appendNumber(this.x)
            .appendNumber(this.y)
            .clause();
    }
    header() {
        return new Uint8Array([0x00, 0x01]);
    }
}
exports.ELine = ELine;

}, function(modId) { var map = {"./basic":1715917493993}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494003, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.ELineDot = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
/**
 * LineDot
 */
class ELineDot extends basic_1.BasicESCArg {
    constructor(options) {
        var _a;
        super();
        this.dot = (_a = options.dot) !== null && _a !== void 0 ? _a : 0;
    }
    clause() {
        return frame_father_1.BinaryCommand.with(this.header())
            .appendNumber(this.dot).clause();
    }
    header() {
        return new Uint8Array([0x1B, 0x4A]);
    }
}
exports.ELineDot = ELineDot;

}, function(modId) { var map = {"./basic":1715917493993}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494004, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.ELocation = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
/**
 * Location
 */
class ELocation extends basic_1.BasicESCArg {
    constructor(options) {
        var _a;
        super();
        this.location = (_a = options.location) !== null && _a !== void 0 ? _a : 0;
    }
    clause() {
        return frame_father_1.BinaryCommand.with(this.header())
            .appendNumber(this.location).clause();
    }
    header() {
        return new Uint8Array([0x1b, 0x61]);
    }
}
exports.ELocation = ELocation;

}, function(modId) { var map = {"./basic":1715917493993}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494005, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EMac = void 0;
const frame_father_1 = require("@psdk/frame-father");
class EMac extends frame_father_1.OnlyBinaryHeaderArg {
    header() {
        return new Uint8Array([0x10, 0xFF, 0x30, 0x12]);
    }
}
exports.EMac = EMac;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494006, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EModel = void 0;
const frame_father_1 = require("@psdk/frame-father");
class EModel extends frame_father_1.OnlyBinaryHeaderArg {
    header() {
        return new Uint8Array([0x10, 0xFF, 0x20, 0xF0]);
    }
}
exports.EModel = EModel;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494007, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EName = void 0;
const frame_father_1 = require("@psdk/frame-father");
class EName extends frame_father_1.OnlyBinaryHeaderArg {
    header() {
        return new Uint8Array([0x10, 0xFF, 0x30, 0x11]);
    }
}
exports.EName = EName;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494008, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EPaperType = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
const types_1 = require("../types");
class EPaperType extends basic_1.BasicESCArg {
    constructor(options) {
        var _a;
        super();
        this.paperType = (_a = options.paperType) !== null && _a !== void 0 ? _a : types_1.PaperType.FOLDED_BLACK_LABEL_PAPER;
    }
    clause() {
        return frame_father_1.BinaryCommand.with(this.header())
            .appendNumber(this.paperType).clause();
    }
    header() {
        return new Uint8Array([0x10, 0xff, 0x10, 0x03]);
    }
}
exports.EPaperType = EPaperType;

}, function(modId) { var map = {"./basic":1715917493993,"../types":1715917493998}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494009, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EPosition = void 0;
const frame_father_1 = require("@psdk/frame-father");
class EPosition extends frame_father_1.OnlyBinaryHeaderArg {
    header() {
        return new Uint8Array([0x1d, 0x0c]);
    }
}
exports.EPosition = EPosition;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494010, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EPrinterVersion = void 0;
const frame_father_1 = require("@psdk/frame-father");
class EPrinterVersion extends frame_father_1.OnlyBinaryHeaderArg {
    header() {
        return new Uint8Array([0x10, 0xFF, 0x20, 0xF1]);
    }
}
exports.EPrinterVersion = EPrinterVersion;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494011, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.ESetShutdownTime = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
class ESetShutdownTime extends basic_1.BasicESCArg {
    constructor(options) {
        var _a;
        super();
        this.time = (_a = options.time) !== null && _a !== void 0 ? _a : 0;
    }
    clause() {
        return frame_father_1.BinaryCommand.with(this.header())
            .appendNumber(this.time / 256)
            .appendNumber(this.time % 256)
            .clause();
    }
    header() {
        return new Uint8Array([0x10, 0xFF, 0x12]);
    }
}
exports.ESetShutdownTime = ESetShutdownTime;

}, function(modId) { var map = {"./basic":1715917493993}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494012, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.ESN = void 0;
const frame_father_1 = require("@psdk/frame-father");
class ESN extends frame_father_1.OnlyBinaryHeaderArg {
    header() {
        return new Uint8Array([0x10, 0xFF, 0x20, 0xF2]);
    }
}
exports.ESN = ESN;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494013, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EState = void 0;
const frame_father_1 = require("@psdk/frame-father");
class EState extends frame_father_1.OnlyBinaryHeaderArg {
    header() {
        return new Uint8Array([0x10, 0xFF, 0x40]);
    }
}
exports.EState = EState;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494014, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EStopJob = void 0;
const frame_father_1 = require("@psdk/frame-father");
class EStopJob extends frame_father_1.OnlyBinaryHeaderArg {
    header() {
        return new Uint8Array([0x10, 0xFF, 0xFE, 0x45]);
    }
}
exports.EStopJob = EStopJob;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494015, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EThickness = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
class EThickness extends basic_1.BasicESCArg {
    constructor(options) {
        var _a;
        super();
        this.thickness = (_a = options.thickness) !== null && _a !== void 0 ? _a : 0;
    }
    clause() {
        return frame_father_1.BinaryCommand.with(this.header())
            .appendNumber(this.thickness).clause();
    }
    header() {
        return new Uint8Array([0x10, 0xFF, 0x10, 0x00]);
    }
}
exports.EThickness = EThickness;

}, function(modId) { var map = {"./basic":1715917493993}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494016, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EVersion = void 0;
const frame_father_1 = require("@psdk/frame-father");
class EVersion extends frame_father_1.OnlyBinaryHeaderArg {
    header() {
        return new Uint8Array([0x10, 0xFF, 0x30, 0x10]);
    }
}
exports.EVersion = EVersion;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494017, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EWakeup = void 0;
const frame_father_1 = require("@psdk/frame-father");
class EWakeup extends frame_father_1.OnlyBinaryHeaderArg {
    header() {
        return new Uint8Array([
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00
        ]);
    }
}
exports.EWakeup = EWakeup;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494018, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EInfo = void 0;
const frame_father_1 = require("@psdk/frame-father");
class EInfo extends frame_father_1.OnlyBinaryHeaderArg {
    header() {
        return new Uint8Array([0x10, 0xFF, 0x70]);
    }
}
exports.EInfo = EInfo;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494019, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EBTType = void 0;
const frame_father_1 = require("@psdk/frame-father");
class EBTType extends frame_father_1.OnlyBinaryHeaderArg {
    header() {
        return new Uint8Array([0x1F, 0xB2, 0x10]);
    }
}
exports.EBTType = EBTType;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494020, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.ESC = void 0;
const generic_1 = require("./generic");
/**
 * ESC entrypoint
 */
class ESC {
    /**
     * Generic esc command
     * @param lifecycle lifecycle
     */
    static generic(lifecycle) {
        return new generic_1.GenericESC(lifecycle);
    }
}
exports.ESC = ESC;

}, function(modId) { var map = {"./generic":1715917493989}; return __REQUIRE__(map[modId], modId); })
return __REQUIRE__(1715917493987);
})()
//miniprogram-npm-outsideDeps=["@psdk/frame-father","@psdk/frame-imageb"]
//# sourceMappingURL=index.js.map