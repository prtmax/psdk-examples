module.exports = (function() {
var __MODS__ = {};
var __DEFINE__ = function(modId, func, req) { var m = { exports: {}, _tempexports: {} }; __MODS__[modId] = { status: 0, func: func, req: req, m: m }; };
var __REQUIRE__ = function(modId, source) { if(!__MODS__[modId]) return require(source); if(!__MODS__[modId].status) { var m = __MODS__[modId].m; m._exports = m._tempexports; var desp = Object.getOwnPropertyDescriptor(m, "exports"); if (desp && desp.configurable) Object.defineProperty(m, "exports", { set: function (val) { if(typeof val === "object" && val !== m._exports) { m._exports.__proto__ = val.__proto__; Object.keys(val).forEach(function (k) { m._exports[k] = val[k]; }); } m._tempexports = val }, get: function () { return m._tempexports; } }); __MODS__[modId].status = 1; __MODS__[modId].func(__MODS__[modId].req, m, m.exports); } return __MODS__[modId].m.exports; };
var __REQUIRE_WILDCARD__ = function(obj) { if(obj && obj.__esModule) { return obj; } else { var newObj = {}; if(obj != null) { for(var k in obj) { if (Object.prototype.hasOwnProperty.call(obj, k)) newObj[k] = obj[k]; } } newObj.default = obj; return newObj; } };
var __REQUIRE_DEFAULT__ = function(obj) { return obj && obj.__esModule ? obj.default : obj; };
__DEFINE__(1795152766969, function(require, module, exports) {

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
__exportStar(require("./types"), exports);

}, function(modId) {var map = {"./impls":1795152766970,"./args":1795152766973,"./types":1795152766982}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1795152766970, function(require, module, exports) {

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

}, function(modId) { var map = {"./generic":1795152766971,"./esc":1795152767012}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1795152766971, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.GenericESC = void 0;
const basic_1 = require("./basic");
class GenericESC extends basic_1.BasicESC {
    constructor(lifecycle) {
        super(lifecycle);
    }
}
exports.GenericESC = GenericESC;

}, function(modId) { var map = {"./basic":1795152766972}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1795152766972, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.BasicESC = void 0;
const frame_father_1 = require("@psdk/frame-father");
const args_1 = require("../args");
class BasicESC extends frame_father_1.PSDK {
    constructor(lifecycle) {
        super();
        /**
         * lifecycle
         * @private
         */
        Object.defineProperty(this, "_lifecycle", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        /**
         * commander
         * @private
         */
        Object.defineProperty(this, "_commander", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
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
     * 使能灰阶
     */
    enableGray() {
        return super.push(new args_1.EEnableGray());
    }
    /**
     * 使能打印模式
     * @param mode 0: 二值化 1: 双色 2: 灰阶
     */
    enableMode(mode) {
        return super.push(new args_1.EEnableMode({ mode }));
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
     * 打印图片(灰阶)
     */
    imageGray(arg) {
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
        return super.push(arg);
    }
    /**
     * 纸张类型(Q1 Q2 Q3 D11 D30 B21 B22用这个)
     */
    paperTypeQ3(arg) {
        return super.push(arg);
    }
    /**
     * 获取当前设备纸张类型(Q1 Q2 Q3 D11 D30 B21 B22用这个)
     * 返回值：0X01 黑标纸，0x02 连续纸，否则:间隙
     */
    getPaperTypeQ3() {
        return super.push(new args_1.EGetPaperTypeQ3());
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
    /**
     * 切刀(立刻切)
     */
    cut() {
        return super.push(new args_1.ECut());
    }
    /**
     * 切刀(固件固定走纸后才切)
     */
    lineDotCut() {
        return super.push(new args_1.ELineDotCut());
    }
    /**
     * 设置当前时间(部分机型适用)
     */
    setCurrentTime(arg) {
        return super.push(arg);
    }
    /**
     *查询NN
     */
    nn() {
        return super.push(new args_1.ENN());
    }
    /**
     * 重置网络信息
     */
    resetNetworkInfo() {
        return super.push(new args_1.EResetNetworkInfo());
    }
}
exports.BasicESC = BasicESC;

}, function(modId) { var map = {"../args":1795152766973}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1795152766973, function(require, module, exports) {

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
__exportStar(require("./enablegray"), exports);
__exportStar(require("./enablemode"), exports);
__exportStar(require("./getshutdowntime"), exports);
__exportStar(require("./image"), exports);
__exportStar(require("./imagegray"), exports);
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
__exportStar(require("./papertypeq3"), exports);
__exportStar(require("./getpapertypeq3"), exports);
__exportStar(require("./cut"), exports);
__exportStar(require("./linedotcut"), exports);
__exportStar(require("./nn"), exports);
__exportStar(require("./resetnetworkinfo"), exports);

}, function(modId) { var map = {"./backlinedot":1795152766974,"./basic":1795152766975,"./batteryvolume":1795152766976,"./enable":1795152766977,"./enablegray":1795152766978,"./enablemode":1795152766979,"./getshutdowntime":1795152766980,"./image":1795152766981,"./imagegray":1795152766986,"./learnlabelgap":1795152766987,"./line":1795152766988,"./linedot":1795152766989,"./location":1795152766990,"./mac":1795152766991,"./model":1795152766992,"./name":1795152766993,"./papertype":1795152766994,"./position":1795152766995,"./printerversion":1795152766996,"./setshutdowntime":1795152766997,"./sn":1795152766998,"./state":1795152766999,"./stopjob":1795152767000,"./thickness":1795152767001,"./version":1795152767002,"./wakeup":1795152767003,"./info":1795152767004,"./bttype":1795152767005,"./papertypeq3":1795152767006,"./getpapertypeq3":1795152767007,"./cut":1795152767008,"./linedotcut":1795152767009,"./nn":1795152767010,"./resetnetworkinfo":1795152767011}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1795152766974, function(require, module, exports) {

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
        Object.defineProperty(this, "dot", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
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

}, function(modId) { var map = {"./basic":1795152766975}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1795152766975, function(require, module, exports) {

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
__DEFINE__(1795152766976, function(require, module, exports) {

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
__DEFINE__(1795152766977, function(require, module, exports) {

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
__DEFINE__(1795152766978, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EEnableGray = void 0;
const frame_father_1 = require("@psdk/frame-father");
/**
 * 使能灰阶打印
 */
class EEnableGray extends frame_father_1.OnlyBinaryHeaderArg {
    header() {
        return new Uint8Array([0x10, 0xFF, 0xBD, 0x02]);
    }
}
exports.EEnableGray = EEnableGray;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1795152766979, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EEnableMode = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
/**
 * 使能打印模式
 */
class EEnableMode extends basic_1.BasicESCArg {
    constructor(options) {
        super();
        Object.defineProperty(this, "mode", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.mode = options.mode;
    }
    clause() {
        return frame_father_1.BinaryCommand.with(this.header())
            .appendNumber(this.mode)
            .clause();
    }
    header() {
        return new Uint8Array([0x10, 0xFF, 0xBD]);
    }
}
exports.EEnableMode = EEnableMode;

}, function(modId) { var map = {"./basic":1795152766975}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1795152766980, function(require, module, exports) {

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
__DEFINE__(1795152766981, function(require, module, exports) {

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
        Object.defineProperty(this, "compress", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "mode", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "image", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "reverse", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "threshold", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
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

}, function(modId) { var map = {"./basic":1795152766975,"../types":1795152766982}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1795152766982, function(require, module, exports) {

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
__exportStar(require("./papertypeq3"), exports);

}, function(modId) { var map = {"./image":1795152766983,"./papertype":1795152766984,"./papertypeq3":1795152766985}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1795152766983, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EImageMode = void 0;
var EImageMode;
(function (EImageMode) {
    EImageMode[EImageMode["NORMAL"] = 0] = "NORMAL";
    EImageMode[EImageMode["DOUBLE_WIDTH"] = 1] = "DOUBLE_WIDTH";
    EImageMode[EImageMode["DOUBLE_HEIGHT"] = 2] = "DOUBLE_HEIGHT";
    EImageMode[EImageMode["DOUBLE_WIDTH_HEIGHT"] = 3] = "DOUBLE_WIDTH_HEIGHT";
})(EImageMode || (exports.EImageMode = EImageMode = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1795152766984, function(require, module, exports) {

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
    /**
     * 打孔纸
     */
    PaperType[PaperType["HOLE_PAPER"] = 3] = "HOLE_PAPER";
    /**
     * 纹身纸
     */
    PaperType[PaperType["TATTOO_PAPER"] = 4] = "TATTOO_PAPER";
    /**
     * 纹身纸（防皱模式）
     */
    PaperType[PaperType["TATTOO_WRINKLES_PAPER"] = 5] = "TATTOO_WRINKLES_PAPER";
    /**
     * 透明黑标纸
     */
    PaperType[PaperType["TRANSPARENT_BLACK_LABEL_PAPER"] = 6] = "TRANSPARENT_BLACK_LABEL_PAPER";
})(PaperType || (exports.PaperType = PaperType = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1795152766985, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.PaperTypeQ3 = void 0;
var PaperTypeQ3;
(function (PaperTypeQ3) {
    /**
     * 不干胶缝隙纸
     */
    PaperTypeQ3[PaperTypeQ3["NO_DRY_ADHESIVE_PAPER"] = 0] = "NO_DRY_ADHESIVE_PAPER";
    /**
     * 透明黑标纸
     */
    PaperTypeQ3[PaperTypeQ3["TRANSPARENT_BLACK_LABEL_PAPER"] = 1] = "TRANSPARENT_BLACK_LABEL_PAPER";
    /**
     * 连续卷筒纸
     */
    PaperTypeQ3[PaperTypeQ3["CONTINUOUS_REEL_PAPER"] = 2] = "CONTINUOUS_REEL_PAPER";
})(PaperTypeQ3 || (exports.PaperTypeQ3 = PaperTypeQ3 = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1795152766986, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EImageGray = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
const frame_imageb_1 = require("@psdk/frame-imageb");
/**
 * 打印图片(灰阶)
 */
class EImageGray extends basic_1.BasicESCArg {
    constructor(options) {
        var _a, _b;
        super();
        Object.defineProperty(this, "compress", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "image", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "reverse", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.compress = (_a = options.compress) !== null && _a !== void 0 ? _a : false;
        this.reverse = (_b = options.reverse) !== null && _b !== void 0 ? _b : false;
        this.image = options.image;
    }
    clause() {
        var _a, _b;
        const processer = new frame_imageb_1.Pbita({
            command: 'esc',
            compress: this.compress,
            reverse: this.reverse,
            gray: true,
        });
        const info = processer.process(this.image);
        const fimage = (_a = info.result) === null || _a === void 0 ? void 0 : _a.data;
        const fbytes = (_b = info.result) === null || _b === void 0 ? void 0 : _b.bytes;
        if (fimage == null || fbytes == null) {
            throw new Error('Wrong image data');
        }
        return frame_father_1.BinaryCommand.with(this.header())
            .appendNumber(fimage.width % 256)
            .appendNumber(Math.floor(fimage.width / 256))
            .appendNumber(fimage.height % 256)
            .appendNumber(Math.floor(fimage.height / 256))
            .appendU8A(fbytes)
            .clause();
    }
    header() {
        return new Uint8Array([0x1D, 0x76, 0x30, 0x00]);
    }
}
exports.EImageGray = EImageGray;

}, function(modId) { var map = {"./basic":1795152766975}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1795152766987, function(require, module, exports) {

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
__DEFINE__(1795152766988, function(require, module, exports) {

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
        Object.defineProperty(this, "x", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "y", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
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

}, function(modId) { var map = {"./basic":1795152766975}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1795152766989, function(require, module, exports) {

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
        Object.defineProperty(this, "dot", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
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

}, function(modId) { var map = {"./basic":1795152766975}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1795152766990, function(require, module, exports) {

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
        Object.defineProperty(this, "location", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
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

}, function(modId) { var map = {"./basic":1795152766975}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1795152766991, function(require, module, exports) {

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
__DEFINE__(1795152766992, function(require, module, exports) {

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
__DEFINE__(1795152766993, function(require, module, exports) {

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
__DEFINE__(1795152766994, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EPaperType = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
const types_1 = require("../types");
class EPaperType extends basic_1.BasicESCArg {
    constructor(options) {
        var _a;
        super();
        Object.defineProperty(this, "paperType", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
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

}, function(modId) { var map = {"./basic":1795152766975,"../types":1795152766982}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1795152766995, function(require, module, exports) {

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
__DEFINE__(1795152766996, function(require, module, exports) {

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
__DEFINE__(1795152766997, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.ESetShutdownTime = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
class ESetShutdownTime extends basic_1.BasicESCArg {
    constructor(options) {
        var _a;
        super();
        Object.defineProperty(this, "time", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
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

}, function(modId) { var map = {"./basic":1795152766975}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1795152766998, function(require, module, exports) {

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
__DEFINE__(1795152766999, function(require, module, exports) {

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
__DEFINE__(1795152767000, function(require, module, exports) {

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
__DEFINE__(1795152767001, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EThickness = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
class EThickness extends basic_1.BasicESCArg {
    constructor(options) {
        var _a;
        super();
        Object.defineProperty(this, "thickness", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
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

}, function(modId) { var map = {"./basic":1795152766975}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1795152767002, function(require, module, exports) {

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
__DEFINE__(1795152767003, function(require, module, exports) {

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
__DEFINE__(1795152767004, function(require, module, exports) {

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
__DEFINE__(1795152767005, function(require, module, exports) {

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
__DEFINE__(1795152767006, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EPaperTypeQ3 = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
const types_1 = require("../types");
class EPaperTypeQ3 extends basic_1.BasicESCArg {
    constructor(options) {
        var _a;
        super();
        Object.defineProperty(this, "paperType", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.paperType = (_a = options.paperType) !== null && _a !== void 0 ? _a : types_1.PaperTypeQ3.CONTINUOUS_REEL_PAPER;
    }
    clause() {
        return frame_father_1.BinaryCommand.with(this.header())
            .appendNumber(this.paperType).clause();
    }
    header() {
        return new Uint8Array([0x10, 0xff, 0x84]);
    }
}
exports.EPaperTypeQ3 = EPaperTypeQ3;

}, function(modId) { var map = {"./basic":1795152766975,"../types":1795152766982}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1795152767007, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EGetPaperTypeQ3 = void 0;
const frame_father_1 = require("@psdk/frame-father");
class EGetPaperTypeQ3 extends frame_father_1.OnlyBinaryHeaderArg {
    header() {
        return new Uint8Array([0x10, 0xFF, 0x85]);
    }
}
exports.EGetPaperTypeQ3 = EGetPaperTypeQ3;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1795152767008, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.ECut = void 0;
const frame_father_1 = require("@psdk/frame-father");
class ECut extends frame_father_1.OnlyBinaryHeaderArg {
    header() {
        return new Uint8Array([0x1d, 0x56, 0x00]);
    }
}
exports.ECut = ECut;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1795152767009, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.ELineDotCut = void 0;
const frame_father_1 = require("@psdk/frame-father");
class ELineDotCut extends frame_father_1.OnlyBinaryHeaderArg {
    header() {
        return new Uint8Array([0x1d, 0x56, 0x42, 0x01]);
    }
}
exports.ELineDotCut = ELineDotCut;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1795152767010, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.ENN = void 0;
const frame_father_1 = require("@psdk/frame-father");
class ENN extends frame_father_1.OnlyBinaryHeaderArg {
    header() {
        return new Uint8Array([0x10, 0xFF, 0x20, 0xF9]);
    }
}
exports.ENN = ENN;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1795152767011, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.EResetNetworkInfo = void 0;
const frame_father_1 = require("@psdk/frame-father");
class EResetNetworkInfo extends frame_father_1.OnlyBinaryHeaderArg {
    header() {
        return new Uint8Array([0x10, 0xFF, 0x33, 0x05]);
    }
}
exports.EResetNetworkInfo = EResetNetworkInfo;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1795152767012, function(require, module, exports) {

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

}, function(modId) { var map = {"./generic":1795152766971}; return __REQUIRE__(map[modId], modId); })
return __REQUIRE__(1795152766969);
})()
//miniprogram-npm-outsideDeps=["@psdk/frame-father","@psdk/frame-imageb"]
//# sourceMappingURL=index.js.map