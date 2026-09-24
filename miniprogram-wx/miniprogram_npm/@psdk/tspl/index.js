module.exports = (function() {
var __MODS__ = {};
var __DEFINE__ = function(modId, func, req) { var m = { exports: {}, _tempexports: {} }; __MODS__[modId] = { status: 0, func: func, req: req, m: m }; };
var __REQUIRE__ = function(modId, source) { if(!__MODS__[modId]) return require(source); if(!__MODS__[modId].status) { var m = __MODS__[modId].m; m._exports = m._tempexports; var desp = Object.getOwnPropertyDescriptor(m, "exports"); if (desp && desp.configurable) Object.defineProperty(m, "exports", { set: function (val) { if(typeof val === "object" && val !== m._exports) { m._exports.__proto__ = val.__proto__; Object.keys(val).forEach(function (k) { m._exports[k] = val[k]; }); } m._tempexports = val }, get: function () { return m._tempexports; } }); __MODS__[modId].status = 1; __MODS__[modId].func(__MODS__[modId].req, m, m.exports); } return __MODS__[modId].m.exports; };
var __REQUIRE_WILDCARD__ = function(obj) { if(obj && obj.__esModule) { return obj; } else { var newObj = {}; if(obj != null) { for(var k in obj) { if (Object.prototype.hasOwnProperty.call(obj, k)) newObj[k] = obj[k]; } } newObj.default = obj; return newObj; } };
var __REQUIRE_DEFAULT__ = function(obj) { return obj && obj.__esModule ? obj.default : obj; };
__DEFINE__(1790237021591, function(require, module, exports) {

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

}, function(modId) {var map = {"./impls":1790237021592,"./args":1790237021595,"./types":1790237021598}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021592, function(require, module, exports) {

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
__exportStar(require("./tspl"), exports);

}, function(modId) { var map = {"./generic":1790237021593,"./tspl":1790237021654}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021593, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.GenericTSPL = void 0;
const basic_1 = require("./basic");
class GenericTSPL extends basic_1.BasicTSPL {
    constructor(lifecycle) {
        super(lifecycle);
    }
}
exports.GenericTSPL = GenericTSPL;

}, function(modId) { var map = {"./basic":1790237021594}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021594, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.BasicTSPL = void 0;
const frame_father_1 = require("@psdk/frame-father");
const args_1 = require("../args");
class BasicTSPL extends frame_father_1.PSDK {
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
     * 创建标签页面大小(mm)
     */
    page(arg) {
        return super.push(arg);
    }
    /**
     * 画线(只能画横竖线)
     */
    bar(arg) {
        return super.push(arg);
    }
    /**
     * 画线(能画斜线)
     */
    line(arg) {
        return super.push(arg);
    }
    /**
     * 一维码
     */
    barcode(arg) {
        return super.push(arg);
    }
    /**
     * 二维码
     */
    qrcode(arg) {
        return super.push(arg);
    }
    /**
     * 打印边框
     */
    box(arg) {
        return super.push(arg);
    }
    /**
     * 画圆
     */
    circle(arg) {
        return super.push(arg);
    }
    /**
     * 画椭圆
     */
    ellipse(arg) {
        return super.push(arg);
    }
    /**
     * 设置打印方向
     */
    direction(arg) {
        return super.push(arg !== null && arg !== void 0 ? arg : new args_1.TDirection());
    }
    /**
     * 使能切刀
     * @param enable true:使能 false:不使能
     */
    cut(enable) {
        return super.push(new args_1.TCut({ enable: enable }));
    }
    /**
     * 定位缝隙
     */
    gap(enable) {
        return super.push(new args_1.TGap({ enable: enable }));
    }
    /**
     * 设置速度
     *
     * @param speed 速度值 （范围1、1.5、2、2.5～6）,建议设置3～4区间
     */
    speed(speed) {
        return super.push(new args_1.TSpeed({ speed: speed }));
    }
    /**
     * 设置浓度
     * @param density 浓度值(0-15)
     */
    density(density) {
        return super.push(new args_1.TDensity({ density: density }));
    }
    /**
     * 清除页面缓冲区
     */
    cls() {
        return super.push(new args_1.TCls());
    }
    /**
     * 打印图片
     */
    image(arg) {
        return super.push(arg);
    }
    /**
     * 打印文本
     */
    text(arg) {
        return super.push(arg);
    }
    /**
     * 打印文本框
     */
    textBox(arg) {
        return super.push(arg);
    }
    reference(arg) {
        return super.push(arg !== null && arg !== void 0 ? arg : new args_1.TReference());
    }
    /**
     * 打印二维条码DATAMATRIX
     */
    dmatrix(arg) {
        return super.push(arg);
    }
    /**
     * 查询状态
     */
    state() {
        return super.push(new args_1.TReadState());
    }
    /**
     * 查询SN
     */
    sn() {
        return super.push(new args_1.TSN());
    }
    /**
     * 查询版本
     */
    version() {
        return super.push(new args_1.TVersion());
    }
    /**
     * 打印标签
     */
    print(copies) {
        return super.push(new args_1.TPrint({ copies: copies }));
    }
    /**
     * 黑标纸打印
     */
    bline() {
        return super.push(new args_1.TBline());
    }
    /**
     * 连续纸打印
     */
    continuous() {
        return super.push(new args_1.TContinuous());
    }
    /**
     * 标签纸打印
     */
    label() {
        return super.push(new args_1.TLabel());
    }
    /**
     * 进纸
     */
    offset(offset) {
        return super.push(new args_1.TOffset({ offset: offset }));
    }
    /**
     * 热转印模式
     */
    ribbon(enable) {
        return super.push(new args_1.TRibbon({ enable: enable }));
    }
    /**
     * 垂直偏移
     */
    shift(shift) {
        return super.push(new args_1.TShift({ shift: shift }));
    }
    /**
     * 查询状态(热敏机器)
     */
    status() {
        return super.push(new args_1.TStatus());
    }
    /**
     * 是否撕去
     */
    tear(enable) {
        return super.push(new args_1.TTear({ enable: enable }));
    }
    /**
     * 是否剥去
     */
    peel(enable) {
        return super.push(new args_1.TPeel({ enable: enable }));
    }
    /**
     * 下载位图(IP-888)
     */
    downloadBmp(fileName, data) {
        return this.push(new args_1.TDownloadBmp({ fileName: fileName, data: data }));
    }
    /**
     * 打印打印机里缓存的图片
     */
    putImage(arg) {
        return super.push(arg);
    }
    /**
     * 红色打印(0-15)
     */
    setRed(density) {
        return super.push(new args_1.TRed({ density: density }));
    }
    /**
     * 黑色打印
     */
    setBlack() {
        return super.push(new args_1.TBlack());
    }
    /**
     * 打印自检页
     */
    selfTest() {
        return super.push(new args_1.TSelfTest());
    }
    /**
     * 设置碳尾开关
     */
    setRibbonEnd(enable) {
        return super.push(new args_1.TSetRibbonEnd({ enable: enable }));
    }
    /**
     * 获取当前碳尾开关(0关，1开)
     */
    getRibbonEnd() {
        return super.push(new args_1.TGetRibbonEnd());
    }
    /**
     * 热转印的版本号获取
     */
    versions() {
        return super.push(new args_1.TVersions());
    }
    /**
     * 热转印的型号获取
     */
    models() {
        return super.push(new args_1.TModels());
    }
    /**
     * 热转印的sn获取
     */
    sns() {
        return super.push(new args_1.TSNs());
    }
    /**
     * 打印机设置成gbk编码
     */
    setGBKCode() {
        return super.push(new args_1.TGBKCode());
    }
    /**
     * 打印机设置成utf-8编码
     */
    setUTF8Code() {
        return super.push(new args_1.TUTF8Code());
    }
    /**
     * 学习纸张（间隙检测）
     */
    learnPaperGap() {
        return super.push(new args_1.TLearnPaperGap());
    }
    /**
     * 读取硬件版本
     */
    readHardwareVersion() {
        return super.push(new args_1.TReadHardwareVersion());
    }
    /**
     * 恢复出厂设置
     */
    resetToFactory() {
        return super.push(new args_1.TResetFactory());
    }
}
exports.BasicTSPL = BasicTSPL;

}, function(modId) { var map = {"../args":1790237021595}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021595, function(require, module, exports) {

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
__exportStar(require("./bar"), exports);
__exportStar(require("./barcode"), exports);
__exportStar(require("./basic"), exports);
__exportStar(require("./box"), exports);
__exportStar(require("./circle"), exports);
__exportStar(require("./cls"), exports);
__exportStar(require("./cut"), exports);
__exportStar(require("./density"), exports);
__exportStar(require("./direction"), exports);
__exportStar(require("./dmatrix"), exports);
__exportStar(require("./gap"), exports);
__exportStar(require("./image"), exports);
__exportStar(require("./page"), exports);
__exportStar(require("./print"), exports);
__exportStar(require("./reference"), exports);
__exportStar(require("./sn"), exports);
__exportStar(require("./speed"), exports);
__exportStar(require("./text"), exports);
__exportStar(require("./version"), exports);
__exportStar(require("./line"), exports);
__exportStar(require("./qrcode"), exports);
__exportStar(require("./readstate"), exports);
__exportStar(require("./textbox"), exports);
__exportStar(require("./bline"), exports);
__exportStar(require("./continuous"), exports);
__exportStar(require("./label"), exports);
__exportStar(require("./offset"), exports);
__exportStar(require("./peel"), exports);
__exportStar(require("./ribbon"), exports);
__exportStar(require("./shift"), exports);
__exportStar(require("./status"), exports);
__exportStar(require("./tear"), exports);
__exportStar(require("./putimage"), exports);
__exportStar(require("./ellipse"), exports);
__exportStar(require("./red"), exports);
__exportStar(require("./black"), exports);
__exportStar(require("./selftest"), exports);
__exportStar(require("./setribbonend"), exports);
__exportStar(require("./getribbonend"), exports);
__exportStar(require("./versions"), exports);
__exportStar(require("./models"), exports);
__exportStar(require("./sns"), exports);
__exportStar(require("./downloadbmp"), exports);
__exportStar(require("./gbkcode"), exports);
__exportStar(require("./utf8code"), exports);
__exportStar(require("./learnpapergap"), exports);
__exportStar(require("./readhardwareversion"), exports);
__exportStar(require("./resetfactory"), exports);

}, function(modId) { var map = {"./bar":1790237021596,"./barcode":1790237021608,"./basic":1790237021597,"./box":1790237021609,"./circle":1790237021610,"./cls":1790237021611,"./cut":1790237021612,"./density":1790237021613,"./direction":1790237021614,"./dmatrix":1790237021615,"./gap":1790237021616,"./image":1790237021617,"./page":1790237021618,"./print":1790237021619,"./reference":1790237021620,"./sn":1790237021621,"./speed":1790237021622,"./text":1790237021623,"./version":1790237021624,"./line":1790237021625,"./qrcode":1790237021626,"./readstate":1790237021627,"./textbox":1790237021628,"./bline":1790237021629,"./continuous":1790237021630,"./label":1790237021631,"./offset":1790237021632,"./peel":1790237021633,"./ribbon":1790237021634,"./shift":1790237021635,"./status":1790237021636,"./tear":1790237021637,"./putimage":1790237021638,"./ellipse":1790237021639,"./red":1790237021640,"./black":1790237021641,"./selftest":1790237021642,"./setribbonend":1790237021643,"./getribbonend":1790237021644,"./versions":1790237021645,"./models":1790237021646,"./sns":1790237021647,"./downloadbmp":1790237021648,"./gbkcode":1790237021649,"./utf8code":1790237021650,"./learnpapergap":1790237021651,"./readhardwareversion":1790237021652,"./resetfactory":1790237021653}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021596, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TBar = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
const types_1 = require("../types");
class TBar extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a, _b, _c, _d, _e;
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
        Object.defineProperty(this, "width", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "height", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "line", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.x = (_a = options === null || options === void 0 ? void 0 : options.x) !== null && _a !== void 0 ? _a : 0;
        this.y = (_b = options === null || options === void 0 ? void 0 : options.y) !== null && _b !== void 0 ? _b : 0;
        this.width = (_c = options === null || options === void 0 ? void 0 : options.width) !== null && _c !== void 0 ? _c : 0;
        this.height = (_d = options === null || options === void 0 ? void 0 : options.height) !== null && _d !== void 0 ? _d : 0;
        this.line = (_e = options === null || options === void 0 ? void 0 : options.line) !== null && _e !== void 0 ? _e : types_1.TTLine.SOLID_LINE;
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header())
            .appendNumber(this.x)
            .appendNumber(this.y)
            .appendNumber(this.width)
            .appendNumber(this.height)
            .appendNumber(this.line)
            .clause();
    }
    header() {
        return 'BAR';
    }
}
exports.TBar = TBar;

}, function(modId) { var map = {"./basic":1790237021597,"../types":1790237021598}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021597, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.BasicTSPLArg = void 0;
const frame_father_1 = require("@psdk/frame-father");
class BasicTSPLArg extends frame_father_1.EasyArg {
    append(arg) {
        super.append(arg);
        return this;
    }
    prepend(arg) {
        super.prepend(arg);
        return this;
    }
}
exports.BasicTSPLArg = BasicTSPLArg;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021598, function(require, module, exports) {

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
__exportStar(require("./font"), exports);
__exportStar(require("./image"), exports);
__exportStar(require("./codetype"), exports);
__exportStar(require("./correctlevel "), exports);
__exportStar(require("./line"), exports);
__exportStar(require("./linem"), exports);
__exportStar(require("./rotation"), exports);
__exportStar(require("./showtype"), exports);
__exportStar(require("./alignment"), exports);

}, function(modId) { var map = {"./font":1790237021599,"./image":1790237021600,"./codetype":1790237021601,"./correctlevel ":1790237021602,"./line":1790237021603,"./linem":1790237021604,"./rotation":1790237021605,"./showtype":1790237021606,"./alignment":1790237021607}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021599, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TFont = void 0;
/**
 * font
 */
var TFont;
(function (TFont) {
    /**
     * 16 bit
     */
    TFont["TSS16"] = "TSS16.BF2";
    /**
     * 24 bit
     */
    TFont["TSS24"] = "TSS24.BF2";
    /**
     * 32 bit
     */
    TFont["TSS32"] = "TSS32.BF2";
})(TFont || (exports.TFont = TFont = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021600, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TImageMode = void 0;
var TImageMode;
(function (TImageMode) {
    TImageMode[TImageMode["OVERWRITE"] = 0] = "OVERWRITE";
    TImageMode[TImageMode["OR"] = 1] = "OR";
    TImageMode[TImageMode["XOR"] = 2] = "XOR";
})(TImageMode || (exports.TImageMode = TImageMode = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021601, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TCodeType = void 0;
/**
 * 条码类型
 */
var TCodeType;
(function (TCodeType) {
    /**
     * 128
     */
    TCodeType["CODE_128"] = "128";
    /**
     * 39
     */
    TCodeType["CODE_39"] = "39";
    /**
     * 93
     */
    TCodeType["CODE_93"] = "93";
    /**
     * ITF
     */
    TCodeType["CODE_ITF"] = "ITF";
    /**
     * UPCA
     */
    TCodeType["CODE_UPCA"] = "UPCA";
    /**
     * UPCE
     */
    TCodeType["CODE_UPCE"] = "UPCE";
    /**
     * CODABAR
     */
    TCodeType["CODE_CODABAR"] = "CODABAR";
    /**
     * EAN8
     */
    TCodeType["CODE_EAN8"] = "EAN8";
    /**
     * EAN13
     */
    TCodeType["CODE_EAN13"] = "EAN13";
})(TCodeType || (exports.TCodeType = TCodeType = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021602, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TCorrectLevel = void 0;
/**
 * 纠错等级
 */
var TCorrectLevel;
(function (TCorrectLevel) {
    /**
     * 纠错等级：L
     */
    TCorrectLevel["L"] = "L";
    /**
     * 纠错等级：M
     */
    TCorrectLevel["M"] = "M";
    /**
     * 纠错等级：Q
     */
    TCorrectLevel["Q"] = "Q";
    /**
     * 纠错等级：H
     */
    TCorrectLevel["H"] = "H";
})(TCorrectLevel || (exports.TCorrectLevel = TCorrectLevel = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021603, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TTLine = void 0;
var TTLine;
(function (TTLine) {
    TTLine[TTLine["SOLID_LINE"] = 0] = "SOLID_LINE";
    TTLine[TTLine["DOTTED_LINE"] = 1] = "DOTTED_LINE";
})(TTLine || (exports.TTLine = TTLine = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021604, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TLineM = void 0;
var TLineM;
(function (TLineM) {
    TLineM["SOLID_LINE"] = "";
    TLineM["DOTTED_LINE_M1"] = "M1";
    TLineM["DOTTED_LINE_M2"] = "M2";
    TLineM["DOTTED_LINE_M3"] = "M3";
    TLineM["DOTTED_LINE_M4"] = "M4";
})(TLineM || (exports.TLineM = TLineM = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021605, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TRotation = void 0;
var TRotation;
(function (TRotation) {
    /**
     * 旋转0度
     */
    TRotation[TRotation["ROTATION_0"] = 0] = "ROTATION_0";
    /**
     * 旋转90度
     */
    TRotation[TRotation["ROTATION_90"] = 90] = "ROTATION_90";
    /**
     * 旋转180度
     */
    TRotation[TRotation["ROTATION_180"] = 180] = "ROTATION_180";
    /**
     * 旋转270度
     */
    TRotation[TRotation["ROTATION_270"] = 270] = "ROTATION_270";
})(TRotation || (exports.TRotation = TRotation = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021606, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TShowType = void 0;
var TShowType;
(function (TShowType) {
    /**
     * 不显示
     */
    TShowType[TShowType["NO_SHOW"] = 0] = "NO_SHOW";
    /**
     * 居左显示
     */
    TShowType[TShowType["SHOW_LEFT"] = 1] = "SHOW_LEFT";
    /**
     * 居中显示
     */
    TShowType[TShowType["SHOW_CENTER"] = 2] = "SHOW_CENTER";
    /**
     * 居右显示
     */
    TShowType[TShowType["SHOW_RIGHT"] = 3] = "SHOW_RIGHT";
})(TShowType || (exports.TShowType = TShowType = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021607, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TAlignment = void 0;
var TAlignment;
(function (TAlignment) {
    /**
     * 默认
     */
    TAlignment[TAlignment["DEFAULT"] = 0] = "DEFAULT";
    /**
     * 左对齐
     */
    TAlignment[TAlignment["LEFT"] = 1] = "LEFT";
    /**
     * 居中
     */
    TAlignment[TAlignment["CENTER"] = 2] = "CENTER";
    /**
     * 右对齐
     */
    TAlignment[TAlignment["RIGHT"] = 3] = "RIGHT";
})(TAlignment || (exports.TAlignment = TAlignment = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021608, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TBarCode = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
const types_1 = require("../types");
class TBarCode extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a, _b, _c, _d, _e, _f, _g, _h;
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
        Object.defineProperty(this, "codeType", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "height", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "showType", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "rotation", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "cellWidth", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "content", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.x = (_a = options === null || options === void 0 ? void 0 : options.x) !== null && _a !== void 0 ? _a : 0;
        this.y = (_b = options === null || options === void 0 ? void 0 : options.y) !== null && _b !== void 0 ? _b : 0;
        this.codeType = (_c = options === null || options === void 0 ? void 0 : options.codeType) !== null && _c !== void 0 ? _c : types_1.TCodeType.CODE_128;
        this.height = (_d = options === null || options === void 0 ? void 0 : options.height) !== null && _d !== void 0 ? _d : 0;
        this.showType = (_e = options === null || options === void 0 ? void 0 : options.showType) !== null && _e !== void 0 ? _e : types_1.TShowType.NO_SHOW;
        this.rotation = (_f = options === null || options === void 0 ? void 0 : options.rotation) !== null && _f !== void 0 ? _f : types_1.TRotation.ROTATION_0;
        this.cellWidth = (_g = options === null || options === void 0 ? void 0 : options.cellWidth) !== null && _g !== void 0 ? _g : 0;
        this.content = (_h = options === null || options === void 0 ? void 0 : options.content) !== null && _h !== void 0 ? _h : '';
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header())
            .appendNumber(this.x)
            .appendNumber(this.y)
            .append(frame_father_1.TextAppendat.create(this.codeType.toString()).quote())
            .appendNumber(this.height)
            .appendNumber(this.showType)
            .appendNumber(this.rotation)
            .appendNumber(this.cellWidth)
            .appendNumber(this.cellWidth)
            .append(frame_father_1.TextAppendat.create(this.content, {
            callback: value => value.replace(/"/gm, '["]')
        }).quote())
            .clause();
    }
    header() {
        return 'BARCODE';
    }
}
exports.TBarCode = TBarCode;

}, function(modId) { var map = {"./basic":1790237021597,"../types":1790237021598}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021609, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TBox = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
class TBox extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a, _b, _c, _d, _e, _f;
        super();
        Object.defineProperty(this, "startX", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "startY", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "endX", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "endY", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "width", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "radius", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.startX = (_a = options === null || options === void 0 ? void 0 : options.startX) !== null && _a !== void 0 ? _a : 0;
        this.startY = (_b = options === null || options === void 0 ? void 0 : options.startY) !== null && _b !== void 0 ? _b : 0;
        this.endX = (_c = options === null || options === void 0 ? void 0 : options.endX) !== null && _c !== void 0 ? _c : 0;
        this.endY = (_d = options === null || options === void 0 ? void 0 : options.endY) !== null && _d !== void 0 ? _d : 0;
        this.width = (_e = options === null || options === void 0 ? void 0 : options.width) !== null && _e !== void 0 ? _e : 0;
        this.radius = (_f = options === null || options === void 0 ? void 0 : options.radius) !== null && _f !== void 0 ? _f : 0;
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header())
            .appendNumber(this.startX)
            .appendNumber(this.startY)
            .appendNumber(this.endX)
            .appendNumber(this.endY)
            .appendNumber(this.width)
            .appendNumber(this.radius)
            .clause();
    }
    header() {
        return 'BOX';
    }
}
exports.TBox = TBox;

}, function(modId) { var map = {"./basic":1790237021597}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021610, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TCircle = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
class TCircle extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a, _b, _c, _d;
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
        Object.defineProperty(this, "width", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "radius", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.x = (_a = options === null || options === void 0 ? void 0 : options.x) !== null && _a !== void 0 ? _a : 0;
        this.y = (_b = options === null || options === void 0 ? void 0 : options.y) !== null && _b !== void 0 ? _b : 0;
        this.width = (_c = options === null || options === void 0 ? void 0 : options.width) !== null && _c !== void 0 ? _c : 0;
        this.radius = (_d = options === null || options === void 0 ? void 0 : options.radius) !== null && _d !== void 0 ? _d : 0;
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header())
            .appendNumber(this.x)
            .appendNumber(this.y)
            .appendNumber(this.width)
            .appendNumber(this.radius)
            .clause();
    }
    header() {
        return 'CIRCLE';
    }
}
exports.TCircle = TCircle;

}, function(modId) { var map = {"./basic":1790237021597}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021611, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TCls = void 0;
const frame_father_1 = require("@psdk/frame-father");
/**
 * Cls command
 */
class TCls extends frame_father_1.OnlyTextHeaderArg {
    constructor() {
        super();
    }
    header() {
        return 'CLS';
    }
}
exports.TCls = TCls;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021612, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TCut = void 0;
const frame_father_1 = require("@psdk/frame-father");
/**
 * enable cut
 */
class TCut extends frame_father_1.OnlyTextHeaderArg {
    constructor(options) {
        var _a;
        super();
        Object.defineProperty(this, "enable", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.enable = (_a = options === null || options === void 0 ? void 0 : options.enable) !== null && _a !== void 0 ? _a : true;
    }
    header() {
        return this.enable ? 'SET CUTTER 1' : 'SET CUTTER OFF';
    }
}
exports.TCut = TCut;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021613, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TDensity = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
/**
 * Print density
 */
class TDensity extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a;
        super();
        Object.defineProperty(this, "density", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.density = (_a = options === null || options === void 0 ? void 0 : options.density) !== null && _a !== void 0 ? _a : 5;
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header())
            .appendNumber(this.density)
            .clause();
    }
    header() {
        return 'DENSITY';
    }
}
exports.TDensity = TDensity;

}, function(modId) { var map = {"./basic":1790237021597}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021614, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.DirectionType = exports.TDirection = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
/**
 * Direction
 */
class TDirection extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a;
        super();
        Object.defineProperty(this, "direction", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.direction = (_a = options.direction) !== null && _a !== void 0 ? _a : DirectionType.ASC;
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header())
            .appendNumber(this.direction)
            .clause();
    }
    header() {
        return 'DIRECTION';
    }
}
exports.TDirection = TDirection;
var DirectionType;
(function (DirectionType) {
    DirectionType[DirectionType["ASC"] = 0] = "ASC";
    DirectionType[DirectionType["DESC"] = 1] = "DESC";
})(DirectionType || (exports.DirectionType = DirectionType = {}));

}, function(modId) { var map = {"./basic":1790237021597}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021615, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TDmatrix = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
class TDmatrix extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a, _b, _c, _d, _e;
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
        Object.defineProperty(this, "width", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "height", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "content", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.x = (_a = options === null || options === void 0 ? void 0 : options.x) !== null && _a !== void 0 ? _a : 0;
        this.y = (_b = options === null || options === void 0 ? void 0 : options.y) !== null && _b !== void 0 ? _b : 0;
        this.width = (_c = options === null || options === void 0 ? void 0 : options.width) !== null && _c !== void 0 ? _c : 0;
        this.height = (_d = options === null || options === void 0 ? void 0 : options.height) !== null && _d !== void 0 ? _d : 0;
        this.content = (_e = options === null || options === void 0 ? void 0 : options.content) !== null && _e !== void 0 ? _e : '';
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header())
            .appendNumber(this.x)
            .appendNumber(this.y)
            .appendNumber(this.width)
            .appendNumber(this.height)
            .append(frame_father_1.TextAppendat.create(this.content, {
            callback: value => value.replace(/"/gm, '["]')
        }).quote())
            .clause();
    }
    header() {
        return 'DMATRIX';
    }
}
exports.TDmatrix = TDmatrix;

}, function(modId) { var map = {"./basic":1790237021597}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021616, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TGap = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
/**
 * Gap of paper
 */
class TGap extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a;
        super();
        Object.defineProperty(this, "enable", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.enable = (_a = options === null || options === void 0 ? void 0 : options.enable) !== null && _a !== void 0 ? _a : true;
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header())
            .appendText(this.enable ? 'ON' : 'OFF')
            .clause();
    }
    header() {
        return 'GAP';
    }
}
exports.TGap = TGap;

}, function(modId) { var map = {"./basic":1790237021597}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021617, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TImage = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
const types_1 = require("../types");
const frame_imageb_1 = require("@psdk/frame-imageb");
/**
 * Image
 */
class TImage extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a, _b, _c, _d, _e, _f;
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
        this.x = (_a = options.x) !== null && _a !== void 0 ? _a : 0;
        this.y = (_b = options.y) !== null && _b !== void 0 ? _b : 0;
        this.compress = (_c = options.compress) !== null && _c !== void 0 ? _c : false;
        this.reverse = (_d = options.reverse) !== null && _d !== void 0 ? _d : false;
        this.threshold = (_e = options.threshold) !== null && _e !== void 0 ? _e : 190;
        this.mode = (_f = options.mode) !== null && _f !== void 0 ? _f : types_1.TImageMode.OVERWRITE;
        this.image = options.image;
    }
    clause() {
        const processer = new frame_imageb_1.Pbita({
            command: 'tspl',
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
        const commander = frame_father_1.Commander.make();
        const ccmd = frame_father_1.TSPLCommand.with(this.header())
            .appendNumber(this.x)
            .appendNumber(this.y)
            .appendNumber(eWidth)
            .appendNumber(height);
        if (this.compress) {
            ccmd.appendNumber(3)
                .appendNumber(fbytes.length);
            commander.pushClause(ccmd.clause(), false)
                .pushText(',', { newline: false })
                .pushBinary(fbytes, false);
        }
        else {
            ccmd.appendNumber(this.mode);
            commander.pushClause(ccmd.clause(), false)
                .pushText(',', { newline: false })
                .pushBinary(fbytes, false);
        }
        commander.newline();
        const command = commander.command();
        return frame_father_1.Raw.binary(command.binary()).clause();
    }
    header() {
        return 'BITMAP';
    }
}
exports.TImage = TImage;

}, function(modId) { var map = {"./basic":1790237021597,"../types":1790237021598}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021618, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TPage = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
/**
 * Page defined
 */
class TPage extends basic_1.BasicTSPLArg {
    constructor(options) {
        super();
        Object.defineProperty(this, "width", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "height", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.width = options.width;
        this.height = options.height;
    }
    header() {
        return 'SIZE';
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header())
            .appendText(`${this.width} mm`)
            .appendText(`${this.height} mm`)
            .clause();
    }
}
exports.TPage = TPage;

}, function(modId) { var map = {"./basic":1790237021597}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021619, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TPrint = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
/**
 * Print command
 */
class TPrint extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a;
        super();
        Object.defineProperty(this, "copies", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.copies = (_a = options === null || options === void 0 ? void 0 : options.copies) !== null && _a !== void 0 ? _a : 1;
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header())
            .appendNumber(1)
            .appendNumber(this.copies)
            .clause();
    }
    header() {
        return 'PRINT';
    }
}
exports.TPrint = TPrint;

}, function(modId) { var map = {"./basic":1790237021597}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021620, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TReference = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
/**
 * Page defined
 */
class TReference extends basic_1.BasicTSPLArg {
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
        this.x = (_a = options === null || options === void 0 ? void 0 : options.x) !== null && _a !== void 0 ? _a : 0;
        this.y = (_b = options === null || options === void 0 ? void 0 : options.y) !== null && _b !== void 0 ? _b : 0;
    }
    header() {
        return 'REFERENCE';
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header())
            .appendNumber(this.x)
            .appendNumber(this.y)
            .clause();
    }
}
exports.TReference = TReference;

}, function(modId) { var map = {"./basic":1790237021597}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021621, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TSN = void 0;
const frame_father_1 = require("@psdk/frame-father");
class TSN extends frame_father_1.OnlyTextHeaderArg {
    constructor() {
        super();
    }
    header() {
        return 'READC PRDOCUTID';
    }
}
exports.TSN = TSN;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021622, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TSpeed = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
/**
 * Print speed
 */
class TSpeed extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a;
        super();
        Object.defineProperty(this, "speed", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.speed = (_a = options === null || options === void 0 ? void 0 : options.speed) !== null && _a !== void 0 ? _a : 6;
    }
    header() {
        return 'SPEED';
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header())
            .appendNumber(this.speed)
            .clause();
    }
}
exports.TSpeed = TSpeed;

}, function(modId) { var map = {"./basic":1790237021597}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021623, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TText = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
const types_1 = require("../types");
/**
 * Text command
 */
class TText extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k;
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
        Object.defineProperty(this, "font", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "rawFont", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "rotation", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "mulX", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "mulY", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "isBold", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "alignment", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "content", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "charset", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.x = (_a = options.x) !== null && _a !== void 0 ? _a : 0;
        this.y = (_b = options.y) !== null && _b !== void 0 ? _b : 0;
        this.font = (_c = options.font) !== null && _c !== void 0 ? _c : types_1.TFont.TSS16;
        this.rawFont = options.rawFont;
        this.rotation = (_d = options.rotation) !== null && _d !== void 0 ? _d : 0;
        this.mulX = (_e = options.mulX) !== null && _e !== void 0 ? _e : 1;
        this.mulY = (_f = options.mulY) !== null && _f !== void 0 ? _f : 1;
        this.isBold = (_g = options.isBold) !== null && _g !== void 0 ? _g : false;
        this.alignment = (_h = options.alignment) !== null && _h !== void 0 ? _h : types_1.TAlignment.DEFAULT;
        this.content = (_j = options.content) !== null && _j !== void 0 ? _j : '';
        this.charset = (_k = options === null || options === void 0 ? void 0 : options.charset) !== null && _k !== void 0 ? _k : 'gbk';
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header(), this.charset)
            .appendNumber(this.x)
            .appendNumber(this.y)
            .append(frame_father_1.TextAppendat.create(this.rawFont != null ? this.rawFont : this.font.toString()).quote())
            .appendNumber(this.rotation)
            .appendNumber(this.mulX)
            .appendNumber(this.mulX)
            .append(frame_father_1.TextAppendat.create("B1", { condition: this.isBold }))
            .append(frame_father_1.TextAppendat.create(this.alignment.toString(), { condition: this.alignment != types_1.TAlignment.DEFAULT }))
            .append(frame_father_1.TextAppendat.create(this.content, {
            callback: value => value.replace(/"/gm, '["]')
        }).quote())
            .clause();
    }
    header() {
        return 'TEXT';
    }
}
exports.TText = TText;

}, function(modId) { var map = {"./basic":1790237021597,"../types":1790237021598}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021624, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TVersion = void 0;
const frame_father_1 = require("@psdk/frame-father");
class TVersion extends frame_father_1.OnlyTextHeaderArg {
    constructor() {
        super();
    }
    header() {
        return 'READC VERSION';
    }
}
exports.TVersion = TVersion;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021625, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TLine = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
const types_1 = require("../types");
class TLine extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a, _b, _c, _d, _e, _f;
        super();
        Object.defineProperty(this, "startX", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "startY", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "endX", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "endY", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "width", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "line", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.startX = (_a = options === null || options === void 0 ? void 0 : options.startX) !== null && _a !== void 0 ? _a : 0;
        this.startY = (_b = options === null || options === void 0 ? void 0 : options.startY) !== null && _b !== void 0 ? _b : 0;
        this.endX = (_c = options === null || options === void 0 ? void 0 : options.endX) !== null && _c !== void 0 ? _c : 0;
        this.endY = (_d = options === null || options === void 0 ? void 0 : options.endY) !== null && _d !== void 0 ? _d : 0;
        this.width = (_e = options === null || options === void 0 ? void 0 : options.width) !== null && _e !== void 0 ? _e : 1;
        this.line = (_f = options === null || options === void 0 ? void 0 : options.line) !== null && _f !== void 0 ? _f : types_1.TLineM.SOLID_LINE;
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header())
            .appendNumber(this.startX)
            .appendNumber(this.startY)
            .appendNumber(this.endX)
            .appendNumber(this.endY)
            .appendNumber(this.width)
            .appendText(this.line)
            .clause();
    }
    header() {
        return 'LINE';
    }
}
exports.TLine = TLine;

}, function(modId) { var map = {"./basic":1790237021597,"../types":1790237021598}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021626, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TQRCode = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
const types_1 = require("../types");
class TQRCode extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a, _b, _c, _d, _e, _f, _g, _h;
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
        Object.defineProperty(this, "correctLevel", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "cellWidth", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "rotation", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "version", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "content", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "charset", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.x = (_a = options === null || options === void 0 ? void 0 : options.x) !== null && _a !== void 0 ? _a : 0;
        this.y = (_b = options === null || options === void 0 ? void 0 : options.y) !== null && _b !== void 0 ? _b : 0;
        this.correctLevel = (_c = options === null || options === void 0 ? void 0 : options.correctLevel) !== null && _c !== void 0 ? _c : types_1.TCorrectLevel.L;
        this.version = (_d = options === null || options === void 0 ? void 0 : options.version) !== null && _d !== void 0 ? _d : '';
        this.rotation = (_e = options === null || options === void 0 ? void 0 : options.rotation) !== null && _e !== void 0 ? _e : types_1.TRotation.ROTATION_0;
        this.cellWidth = (_f = options === null || options === void 0 ? void 0 : options.cellWidth) !== null && _f !== void 0 ? _f : 0;
        this.content = (_g = options === null || options === void 0 ? void 0 : options.content) !== null && _g !== void 0 ? _g : '';
        this.charset = (_h = options === null || options === void 0 ? void 0 : options.charset) !== null && _h !== void 0 ? _h : 'gbk';
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header(), this.charset)
            .appendNumber(this.x)
            .appendNumber(this.y)
            .appendText(this.correctLevel)
            .appendNumber(this.cellWidth)
            .appendText('A')
            .appendNumber(this.rotation)
            .appendText('M2')
            .appendText('S7')
            .append(frame_father_1.TextAppendat.create('V' + this.version, {
            condition: this.version != null && this.version != ''
        }))
            .append(frame_father_1.TextAppendat.create(this.content, {
            callback: value => value.replace(/"/gm, '["]')
        }).quote())
            .clause();
    }
    header() {
        return 'QRCODE';
    }
}
exports.TQRCode = TQRCode;

}, function(modId) { var map = {"./basic":1790237021597,"../types":1790237021598}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021627, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TReadState = void 0;
const frame_father_1 = require("@psdk/frame-father");
class TReadState extends frame_father_1.OnlyTextHeaderArg {
    constructor() {
        super();
    }
    header() {
        return 'READSTA';
    }
}
exports.TReadState = TReadState;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021628, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TTextBox = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
const types_1 = require("../types");
/**
 * Text command
 */
class TTextBox extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l;
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
        Object.defineProperty(this, "font", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "rotation", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "rotationType", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "mulX", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "mulY", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "width", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "lineSpace", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "isBold", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "content", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.x = (_a = options.x) !== null && _a !== void 0 ? _a : 0;
        this.y = (_b = options.y) !== null && _b !== void 0 ? _b : 0;
        this.font = (_c = options.font) !== null && _c !== void 0 ? _c : types_1.TFont.TSS16;
        this.rotation = (_d = options.rotation) !== null && _d !== void 0 ? _d : types_1.TRotation.ROTATION_0;
        this.mulX = (_e = options.mulX) !== null && _e !== void 0 ? _e : 0;
        this.mulY = (_f = options.mulY) !== null && _f !== void 0 ? _f : 0;
        this.width = (_g = options.width) !== null && _g !== void 0 ? _g : 0;
        this.lineSpace = (_h = options.lineSpace) !== null && _h !== void 0 ? _h : 0;
        this.rotationType = (_j = options.rotationType) !== null && _j !== void 0 ? _j : false;
        this.isBold = (_k = options.isBold) !== null && _k !== void 0 ? _k : false;
        this.content = (_l = options.content) !== null && _l !== void 0 ? _l : '';
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header())
            .appendNumber(this.x)
            .appendNumber(this.y)
            .append(frame_father_1.TextAppendat.create(this.font.toString()).quote())
            .appendNumber(this.rotation)
            .appendNumber(this.mulX)
            .appendNumber(this.mulX)
            .appendNumber(this.width)
            .append(frame_father_1.TextAppendat.create('L' + this.lineSpace, { condition: this.lineSpace > 0 }))
            .append(frame_father_1.TextAppendat.create('B1' + this.isBold, { condition: this.isBold }))
            .append(frame_father_1.TextAppendat.create('D' + this.rotation, { condition: this.rotationType }))
            .append(frame_father_1.TextAppendat.create(this.content, {
            callback: value => value.replace(/"/gm, '["]')
        }).quote())
            .clause();
    }
    header() {
        return 'TEXTBOX';
    }
}
exports.TTextBox = TTextBox;

}, function(modId) { var map = {"./basic":1790237021597,"../types":1790237021598}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021629, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TBline = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
class TBline extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a, _b;
        super();
        Object.defineProperty(this, "height", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "offset", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.height = (_a = options === null || options === void 0 ? void 0 : options.height) !== null && _a !== void 0 ? _a : 3;
        this.offset = (_b = options === null || options === void 0 ? void 0 : options.offset) !== null && _b !== void 0 ? _b : 0;
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header())
            .appendText(`${this.height} mm`)
            .appendText(`${this.offset} mm`)
            .clause();
    }
    header() {
        return 'BLINE';
    }
}
exports.TBline = TBline;

}, function(modId) { var map = {"./basic":1790237021597}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021630, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TContinuous = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
class TContinuous extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a, _b;
        super();
        Object.defineProperty(this, "height", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "offset", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.height = (_a = options === null || options === void 0 ? void 0 : options.height) !== null && _a !== void 0 ? _a : 0;
        this.offset = (_b = options === null || options === void 0 ? void 0 : options.offset) !== null && _b !== void 0 ? _b : 0;
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header())
            .appendText(`${this.height} mm`)
            .appendText(`${this.offset} mm`)
            .clause();
    }
    header() {
        return 'GAP';
    }
}
exports.TContinuous = TContinuous;

}, function(modId) { var map = {"./basic":1790237021597}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021631, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TLabel = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
class TLabel extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a, _b;
        super();
        Object.defineProperty(this, "height", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "offset", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.height = (_a = options === null || options === void 0 ? void 0 : options.height) !== null && _a !== void 0 ? _a : 3;
        this.offset = (_b = options === null || options === void 0 ? void 0 : options.offset) !== null && _b !== void 0 ? _b : 0;
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header())
            .appendText(`${this.height} mm`)
            .appendText(`${this.offset} mm`)
            .clause();
    }
    header() {
        return 'GAP';
    }
}
exports.TLabel = TLabel;

}, function(modId) { var map = {"./basic":1790237021597}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021632, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TOffset = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
class TOffset extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a;
        super();
        Object.defineProperty(this, "offset", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.offset = (_a = options === null || options === void 0 ? void 0 : options.offset) !== null && _a !== void 0 ? _a : 0;
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header())
            .appendText(`${this.offset} mm`)
            .clause();
    }
    header() {
        return 'OFFSET';
    }
}
exports.TOffset = TOffset;

}, function(modId) { var map = {"./basic":1790237021597}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021633, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TPeel = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
/**
 * Peel of paper
 */
class TPeel extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a;
        super();
        Object.defineProperty(this, "enable", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.enable = (_a = options === null || options === void 0 ? void 0 : options.enable) !== null && _a !== void 0 ? _a : true;
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header())
            .appendText(this.enable ? 'ON' : 'OFF')
            .clause();
    }
    header() {
        return 'SET PEEL';
    }
}
exports.TPeel = TPeel;

}, function(modId) { var map = {"./basic":1790237021597}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021634, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TRibbon = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
class TRibbon extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a;
        super();
        Object.defineProperty(this, "enable", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.enable = (_a = options === null || options === void 0 ? void 0 : options.enable) !== null && _a !== void 0 ? _a : true;
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header())
            .appendText(this.enable ? 'ON' : 'OFF')
            .clause();
    }
    header() {
        return 'SET RIBBON';
    }
}
exports.TRibbon = TRibbon;

}, function(modId) { var map = {"./basic":1790237021597}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021635, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TShift = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
class TShift extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a;
        super();
        Object.defineProperty(this, "shift", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.shift = (_a = options === null || options === void 0 ? void 0 : options.shift) !== null && _a !== void 0 ? _a : 0;
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header())
            .appendNumber(this.shift)
            .clause();
    }
    header() {
        return 'SHIFT';
    }
}
exports.TShift = TShift;

}, function(modId) { var map = {"./basic":1790237021597}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021636, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TStatus = void 0;
const frame_father_1 = require("@psdk/frame-father");
class TStatus extends frame_father_1.OnlyBinaryHeaderArg {
    header() {
        return new Uint8Array([0x1B, 0x21, 0x3F]);
    }
}
exports.TStatus = TStatus;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021637, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TTear = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
/**
 * Tear of paper
 */
class TTear extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a;
        super();
        Object.defineProperty(this, "enable", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.enable = (_a = options === null || options === void 0 ? void 0 : options.enable) !== null && _a !== void 0 ? _a : true;
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header())
            .appendText(this.enable ? 'ON' : 'OFF')
            .clause();
    }
    header() {
        return 'SET TEAR';
    }
}
exports.TTear = TTear;

}, function(modId) { var map = {"./basic":1790237021597}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021638, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TPutImage = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
class TPutImage extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a, _b, _c, _d;
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
        Object.defineProperty(this, "filename", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "charset", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.x = (_a = options.x) !== null && _a !== void 0 ? _a : 0;
        this.y = (_b = options.y) !== null && _b !== void 0 ? _b : 0;
        this.filename = (_c = options.filename) !== null && _c !== void 0 ? _c : '';
        this.charset = (_d = options === null || options === void 0 ? void 0 : options.charset) !== null && _d !== void 0 ? _d : 'gbk';
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header(), this.charset)
            .appendNumber(this.x)
            .appendNumber(this.y)
            .append(frame_father_1.TextAppendat.create(this.filename, {
            callback: value => value.replace(/"/gm, '["]')
        }).quote())
            .clause();
    }
    header() {
        return 'PUTBMP';
    }
}
exports.TPutImage = TPutImage;

}, function(modId) { var map = {"./basic":1790237021597}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021639, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TEllipse = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
class TEllipse extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a, _b, _c, _d, _e;
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
        Object.defineProperty(this, "width", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "height", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "thickness", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.x = (_a = options === null || options === void 0 ? void 0 : options.x) !== null && _a !== void 0 ? _a : 0;
        this.y = (_b = options === null || options === void 0 ? void 0 : options.y) !== null && _b !== void 0 ? _b : 0;
        this.width = (_c = options === null || options === void 0 ? void 0 : options.width) !== null && _c !== void 0 ? _c : 0;
        this.height = (_d = options === null || options === void 0 ? void 0 : options.height) !== null && _d !== void 0 ? _d : 0;
        this.thickness = (_e = options === null || options === void 0 ? void 0 : options.thickness) !== null && _e !== void 0 ? _e : 0;
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header())
            .appendNumber(this.x)
            .appendNumber(this.y)
            .appendNumber(this.width)
            .appendNumber(this.height)
            .appendNumber(this.thickness)
            .clause();
    }
    header() {
        return 'ELLIPSE';
    }
}
exports.TEllipse = TEllipse;

}, function(modId) { var map = {"./basic":1790237021597}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021640, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TRed = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
class TRed extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a;
        super();
        Object.defineProperty(this, "density", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.density = (_a = options === null || options === void 0 ? void 0 : options.density) !== null && _a !== void 0 ? _a : 10;
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header())
            .appendNumber(this.density)
            .clause();
    }
    header() {
        return 'SETCOLOR RED';
    }
}
exports.TRed = TRed;

}, function(modId) { var map = {"./basic":1790237021597}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021641, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TBlack = void 0;
const frame_father_1 = require("@psdk/frame-father");
class TBlack extends frame_father_1.OnlyTextHeaderArg {
    constructor() {
        super();
    }
    header() {
        return 'SETCOLOR BLACK';
    }
}
exports.TBlack = TBlack;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021642, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TSelfTest = void 0;
const frame_father_1 = require("@psdk/frame-father");
class TSelfTest extends frame_father_1.OnlyTextHeaderArg {
    constructor() {
        super();
    }
    header() {
        return 'SELFTEST';
    }
}
exports.TSelfTest = TSelfTest;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021643, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TSetRibbonEnd = void 0;
const frame_father_1 = require("@psdk/frame-father");
/**
 * enable cut
 */
class TSetRibbonEnd extends frame_father_1.OnlyTextHeaderArg {
    constructor(options) {
        var _a;
        super();
        Object.defineProperty(this, "enable", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.enable = (_a = options === null || options === void 0 ? void 0 : options.enable) !== null && _a !== void 0 ? _a : true;
    }
    header() {
        return this.enable ? 'SET RIBBONEND ON' : 'SET RIBBONEND OFF';
    }
}
exports.TSetRibbonEnd = TSetRibbonEnd;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021644, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TGetRibbonEnd = void 0;
const frame_father_1 = require("@psdk/frame-father");
class TGetRibbonEnd extends frame_father_1.OnlyTextHeaderArg {
    constructor() {
        super();
    }
    header() {
        return 'DIAGNOSTIC REPORT RIBBONEND';
    }
}
exports.TGetRibbonEnd = TGetRibbonEnd;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021645, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TVersions = void 0;
const frame_father_1 = require("@psdk/frame-father");
class TVersions extends frame_father_1.OnlyTextHeaderArg {
    constructor() {
        super();
    }
    header() {
        return 'OUT GETSETTING$(\"SYSTEM\",\"INFORMATION\",\"VERSION\")';
    }
}
exports.TVersions = TVersions;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021646, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TModels = void 0;
const frame_father_1 = require("@psdk/frame-father");
class TModels extends frame_father_1.OnlyTextHeaderArg {
    constructor() {
        super();
    }
    header() {
        return 'OUT GETSETTING$(\"SYSTEM\",\"INFORMATION\",\"MODEL\")';
    }
}
exports.TModels = TModels;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021647, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TSNs = void 0;
const frame_father_1 = require("@psdk/frame-father");
class TSNs extends frame_father_1.OnlyTextHeaderArg {
    constructor() {
        super();
    }
    header() {
        return 'OUT GETSETTING$(\"SYSTEM\",\"INFORMATION\",\"SERIAL\")';
    }
}
exports.TSNs = TSNs;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021648, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TDownloadBmp = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
/**
 * 下载图片到打印机
 */
class TDownloadBmp extends basic_1.BasicTSPLArg {
    constructor(options) {
        super();
        Object.defineProperty(this, "fileName", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "data", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.fileName = options.fileName;
        this.data = options.data;
    }
    clause() {
        const alignData = this.align32(this.data);
        const tc = frame_father_1.TSPLCommand.with(this.header())
            .appendText('F')
            .append(frame_father_1.TextAppendat.create(this.fileName).quote())
            .appendNumber(alignData.length);
        const command = frame_father_1.Commander.make()
            .pushClause(tc.clause(), false)
            .pushText(',', { newline: false })
            .pushBinary(alignData, false)
            .newline()
            .command();
        return frame_father_1.Raw.binary(command.binary()).clause();
    }
    header() {
        return 'DOWNLOAD';
    }
    //32位对齐
    align32(data) {
        const bmpSize = data.length;
        const bmpOffset = this.getOffset(data);
        const width = this.getWidth(data);
        let linewidth4cha = 0;
        if (width % 32 !== 0) {
            linewidth4cha = (Math.floor(width / 32) + 1) * 4;
        }
        else {
            linewidth4cha = Math.floor(width / 32) * 4;
        }
        const widthshengyu = width % 8;
        let linewidth1cha = 0;
        if (width % 8 !== 0) {
            linewidth1cha = Math.floor(width / 8) + 1;
        }
        else {
            linewidth1cha = Math.floor(width / 8);
        }
        const datas = new Uint8Array(bmpSize);
        for (let index = 0; index < bmpSize; index++) {
            if (index >= bmpOffset) {
                if (widthshengyu === 0) {
                    if ((index - bmpOffset) % linewidth4cha < linewidth1cha)
                        datas[index] = data[index];
                    else
                        datas[index] = 0xff;
                }
                else {
                    if ((index - bmpOffset) % linewidth4cha < (linewidth1cha - 1))
                        datas[index] = data[index];
                    else if ((index - bmpOffset) % linewidth4cha === (linewidth1cha - 1))
                        datas[index] = (data[index] & ((0xff << (8 - widthshengyu))));
                    else
                        datas[index] = 0xff;
                }
            }
            else {
                datas[index] = data[index];
            }
        }
        return datas;
    }
    getWidth(data) {
        return ((this.getUint(data[0x15]) * 256 * 256 * 256) +
            (this.getUint(data[0x14]) * 256 * 256) +
            (this.getUint(data[0x13]) * 256) +
            this.getUint(data[0x12]));
    }
    getOffset(data) {
        return ((this.getUint(data[0x0d]) * 256 * 256 * 256) +
            (this.getUint(data[0x0c]) * 256 * 256) +
            (this.getUint(data[0x0b]) * 256) +
            this.getUint(data[0x0a]));
    }
    getUint(data) {
        if (data < 0)
            return data + 256;
        else
            return data;
    }
}
exports.TDownloadBmp = TDownloadBmp;

}, function(modId) { var map = {"./basic":1790237021597}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021649, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TGBKCode = void 0;
const frame_father_1 = require("@psdk/frame-father");
class TGBKCode extends frame_father_1.OnlyTextHeaderArg {
    constructor() {
        super();
    }
    header() {
        return 'CODEPAGE 936';
    }
}
exports.TGBKCode = TGBKCode;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021650, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TUTF8Code = void 0;
const frame_father_1 = require("@psdk/frame-father");
class TUTF8Code extends frame_father_1.OnlyTextHeaderArg {
    constructor() {
        super();
    }
    header() {
        return 'CODEPAGE UTF-8';
    }
}
exports.TUTF8Code = TUTF8Code;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021651, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TLearnPaperGap = void 0;
const frame_father_1 = require("@psdk/frame-father");
class TLearnPaperGap extends frame_father_1.OnlyTextHeaderArg {
    constructor() {
        super();
    }
    header() {
        return 'GAPDETECT';
    }
}
exports.TLearnPaperGap = TLearnPaperGap;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021652, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TReadHardwareVersion = void 0;
const frame_father_1 = require("@psdk/frame-father");
class TReadHardwareVersion extends frame_father_1.OnlyTextHeaderArg {
    constructor() {
        super();
    }
    header() {
        return 'READC HW_VERSION';
    }
}
exports.TReadHardwareVersion = TReadHardwareVersion;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021653, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TResetFactory = void 0;
const frame_father_1 = require("@psdk/frame-father");
class TResetFactory extends frame_father_1.OnlyTextHeaderArg {
    constructor() {
        super();
    }
    header() {
        return 'RESET FACTORY';
    }
}
exports.TResetFactory = TResetFactory;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1790237021654, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TSPL = void 0;
const generic_1 = require("./generic");
/**
 * TSPL entrypoint
 */
class TSPL {
    /**
     * Generic tspl command
     * @param lifecycle lifecycle
     */
    static generic(lifecycle) {
        return new generic_1.GenericTSPL(lifecycle);
    }
}
exports.TSPL = TSPL;

}, function(modId) { var map = {"./generic":1790237021593}; return __REQUIRE__(map[modId], modId); })
return __REQUIRE__(1790237021591);
})()
//miniprogram-npm-outsideDeps=["@psdk/frame-father","@psdk/frame-imageb"]
//# sourceMappingURL=index.js.map