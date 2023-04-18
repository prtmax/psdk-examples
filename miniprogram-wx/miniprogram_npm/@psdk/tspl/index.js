module.exports = (function() {
var __MODS__ = {};
var __DEFINE__ = function(modId, func, req) { var m = { exports: {}, _tempexports: {} }; __MODS__[modId] = { status: 0, func: func, req: req, m: m }; };
var __REQUIRE__ = function(modId, source) { if(!__MODS__[modId]) return require(source); if(!__MODS__[modId].status) { var m = __MODS__[modId].m; m._exports = m._tempexports; var desp = Object.getOwnPropertyDescriptor(m, "exports"); if (desp && desp.configurable) Object.defineProperty(m, "exports", { set: function (val) { if(typeof val === "object" && val !== m._exports) { m._exports.__proto__ = val.__proto__; Object.keys(val).forEach(function (k) { m._exports[k] = val[k]; }); } m._tempexports = val }, get: function () { return m._tempexports; } }); __MODS__[modId].status = 1; __MODS__[modId].func(__MODS__[modId].req, m, m.exports); } return __MODS__[modId].m.exports; };
var __REQUIRE_WILDCARD__ = function(obj) { if(obj && obj.__esModule) { return obj; } else { var newObj = {}; if(obj != null) { for(var k in obj) { if (Object.prototype.hasOwnProperty.call(obj, k)) newObj[k] = obj[k]; } } newObj.default = obj; return newObj; } };
var __REQUIRE_DEFAULT__ = function(obj) { return obj && obj.__esModule ? obj.default : obj; };
__DEFINE__(1681364782013, function(require, module, exports) {

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

}, function(modId) {var map = {"./impls":1681364782014,"./args":1681364782017,"./types":1681364782020}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782014, function(require, module, exports) {

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

}, function(modId) { var map = {"./generic":1681364782015,"./tspl":1681364782050}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782015, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.GenericTSPL = void 0;
const basic_1 = require("./basic");
class GenericTSPL extends basic_1.BasicTSPL {
    constructor(lifecycle) {
        super(lifecycle);
    }
}
exports.GenericTSPL = GenericTSPL;

}, function(modId) { var map = {"./basic":1681364782016}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782016, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.BasicTSPL = void 0;
const frame_father_1 = require("@psdk/frame-father");
const args_1 = require("../args");
class BasicTSPL extends frame_father_1.PSDK {
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
}
exports.BasicTSPL = BasicTSPL;

}, function(modId) { var map = {"../args":1681364782017}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782017, function(require, module, exports) {

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

}, function(modId) { var map = {"./bar":1681364782018,"./barcode":1681364782029,"./basic":1681364782019,"./box":1681364782030,"./circle":1681364782031,"./cls":1681364782032,"./cut":1681364782033,"./density":1681364782034,"./direction":1681364782035,"./dmatrix":1681364782036,"./gap":1681364782037,"./image":1681364782038,"./page":1681364782039,"./print":1681364782040,"./reference":1681364782041,"./sn":1681364782042,"./speed":1681364782043,"./text":1681364782044,"./version":1681364782045,"./line":1681364782046,"./qrcode":1681364782047,"./readstate":1681364782048,"./textbox":1681364782049}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782018, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TBar = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
const types_1 = require("../types");
class TBar extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a, _b, _c, _d, _e;
        super();
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

}, function(modId) { var map = {"./basic":1681364782019,"../types":1681364782020}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782019, function(require, module, exports) {

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
__DEFINE__(1681364782020, function(require, module, exports) {

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

}, function(modId) { var map = {"./font":1681364782021,"./image":1681364782022,"./codetype":1681364782023,"./correctlevel ":1681364782024,"./line":1681364782025,"./linem":1681364782026,"./rotation":1681364782027,"./showtype":1681364782028}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782021, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.Alignment = exports.TFont = void 0;
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
})(TFont = exports.TFont || (exports.TFont = {}));
/**
 * Alignment
 */
var Alignment;
(function (Alignment) {
    Alignment["B1"] = "B1";
})(Alignment = exports.Alignment || (exports.Alignment = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782022, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TImageMode = void 0;
var TImageMode;
(function (TImageMode) {
    TImageMode[TImageMode["OVERWRITE"] = 0] = "OVERWRITE";
    TImageMode[TImageMode["OR"] = 1] = "OR";
    TImageMode[TImageMode["XOR"] = 2] = "XOR";
})(TImageMode = exports.TImageMode || (exports.TImageMode = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782023, function(require, module, exports) {

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
})(TCodeType = exports.TCodeType || (exports.TCodeType = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782024, function(require, module, exports) {

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
})(TCorrectLevel = exports.TCorrectLevel || (exports.TCorrectLevel = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782025, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TTLine = void 0;
var TTLine;
(function (TTLine) {
    TTLine[TTLine["SOLID_LINE"] = 0] = "SOLID_LINE";
    TTLine[TTLine["DOTTED_LINE"] = 1] = "DOTTED_LINE";
})(TTLine = exports.TTLine || (exports.TTLine = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782026, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TLineM = void 0;
var TLineM;
(function (TLineM) {
    TLineM["SOLID_LINE"] = "";
    TLineM["DOTTED_LINE_M1"] = "M1";
    TLineM["DOTTED_LINE_M2"] = "M2";
    TLineM["DOTTED_LINE_M3"] = "M3";
    TLineM["DOTTED_LINE_M4"] = "M4";
})(TLineM = exports.TLineM || (exports.TLineM = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782027, function(require, module, exports) {

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
})(TRotation = exports.TRotation || (exports.TRotation = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782028, function(require, module, exports) {

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
})(TShowType = exports.TShowType || (exports.TShowType = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782029, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TBarCode = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
const types_1 = require("../types");
class TBarCode extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a, _b, _c, _d, _e, _f, _g, _h;
        super();
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

}, function(modId) { var map = {"./basic":1681364782019,"../types":1681364782020}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782030, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TBox = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
class TBox extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a, _b, _c, _d, _e, _f;
        super();
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

}, function(modId) { var map = {"./basic":1681364782019}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782031, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TCircle = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
class TCircle extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a, _b, _c, _d;
        super();
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

}, function(modId) { var map = {"./basic":1681364782019}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782032, function(require, module, exports) {

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
__DEFINE__(1681364782033, function(require, module, exports) {

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
        this.enable = (_a = options === null || options === void 0 ? void 0 : options.enable) !== null && _a !== void 0 ? _a : true;
    }
    header() {
        return this.enable ? 'SET CUTTER 1' : 'SET CUTTER OFF';
    }
}
exports.TCut = TCut;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782034, function(require, module, exports) {

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

}, function(modId) { var map = {"./basic":1681364782019}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782035, function(require, module, exports) {

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
})(DirectionType = exports.DirectionType || (exports.DirectionType = {}));

}, function(modId) { var map = {"./basic":1681364782019}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782036, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TDmatrix = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
class TDmatrix extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a, _b, _c, _d, _e;
        super();
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

}, function(modId) { var map = {"./basic":1681364782019}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782037, function(require, module, exports) {

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

}, function(modId) { var map = {"./basic":1681364782019}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782038, function(require, module, exports) {

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

}, function(modId) { var map = {"./basic":1681364782019,"../types":1681364782020}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782039, function(require, module, exports) {

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

}, function(modId) { var map = {"./basic":1681364782019}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782040, function(require, module, exports) {

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

}, function(modId) { var map = {"./basic":1681364782019}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782041, function(require, module, exports) {

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

}, function(modId) { var map = {"./basic":1681364782019}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782042, function(require, module, exports) {

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
__DEFINE__(1681364782043, function(require, module, exports) {

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

}, function(modId) { var map = {"./basic":1681364782019}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782044, function(require, module, exports) {

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
        var _a, _b, _c, _d, _e, _f, _g, _h, _j;
        super();
        this.x = (_a = options.x) !== null && _a !== void 0 ? _a : 0;
        this.y = (_b = options.y) !== null && _b !== void 0 ? _b : 0;
        this.font = (_c = options.font) !== null && _c !== void 0 ? _c : types_1.TFont.TSS16;
        this.rotation = (_d = options.rotation) !== null && _d !== void 0 ? _d : 0;
        this.mulX = (_e = options.mulX) !== null && _e !== void 0 ? _e : 0;
        this.mulY = (_f = options.mulY) !== null && _f !== void 0 ? _f : 0;
        this.alignment = (_g = options.alignment) !== null && _g !== void 0 ? _g : types_1.Alignment.B1;
        this.content = (_h = options.content) !== null && _h !== void 0 ? _h : '';
        this.charset = (_j = options === null || options === void 0 ? void 0 : options.charset) !== null && _j !== void 0 ? _j : 'gbk';
    }
    clause() {
        return frame_father_1.TSPLCommand.with(this.header(), this.charset)
            .appendNumber(this.x)
            .appendNumber(this.y)
            .append(frame_father_1.TextAppendat.create(this.font.toString()).quote())
            .appendNumber(this.rotation)
            .appendNumber(this.mulX)
            .appendNumber(this.mulX)
            .appendText(this.alignment.toString())
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

}, function(modId) { var map = {"./basic":1681364782019,"../types":1681364782020}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782045, function(require, module, exports) {

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
__DEFINE__(1681364782046, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TLine = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
const types_1 = require("../types");
class TLine extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a, _b, _c, _d, _e, _f;
        super();
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

}, function(modId) { var map = {"./basic":1681364782019,"../types":1681364782020}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782047, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.TQRCode = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
const types_1 = require("../types");
class TQRCode extends basic_1.BasicTSPLArg {
    constructor(options) {
        var _a, _b, _c, _d, _e, _f, _g, _h;
        super();
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

}, function(modId) { var map = {"./basic":1681364782019,"../types":1681364782020}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782048, function(require, module, exports) {

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
__DEFINE__(1681364782049, function(require, module, exports) {

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

}, function(modId) { var map = {"./basic":1681364782019,"../types":1681364782020}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1681364782050, function(require, module, exports) {

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

}, function(modId) { var map = {"./generic":1681364782015}; return __REQUIRE__(map[modId], modId); })
return __REQUIRE__(1681364782013);
})()
//miniprogram-npm-outsideDeps=["@psdk/frame-father","@psdk/frame-imageb"]
//# sourceMappingURL=index.js.map