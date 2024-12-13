module.exports = (function() {
var __MODS__ = {};
var __DEFINE__ = function(modId, func, req) { var m = { exports: {}, _tempexports: {} }; __MODS__[modId] = { status: 0, func: func, req: req, m: m }; };
var __REQUIRE__ = function(modId, source) { if(!__MODS__[modId]) return require(source); if(!__MODS__[modId].status) { var m = __MODS__[modId].m; m._exports = m._tempexports; var desp = Object.getOwnPropertyDescriptor(m, "exports"); if (desp && desp.configurable) Object.defineProperty(m, "exports", { set: function (val) { if(typeof val === "object" && val !== m._exports) { m._exports.__proto__ = val.__proto__; Object.keys(val).forEach(function (k) { m._exports[k] = val[k]; }); } m._tempexports = val }, get: function () { return m._tempexports; } }); __MODS__[modId].status = 1; __MODS__[modId].func(__MODS__[modId].req, m, m.exports); } return __MODS__[modId].m.exports; };
var __REQUIRE_WILDCARD__ = function(obj) { if(obj && obj.__esModule) { return obj; } else { var newObj = {}; if(obj != null) { for(var k in obj) { if (Object.prototype.hasOwnProperty.call(obj, k)) newObj[k] = obj[k]; } } newObj.default = obj; return newObj; } };
var __REQUIRE_DEFAULT__ = function(obj) { return obj && obj.__esModule ? obj.default : obj; };
__DEFINE__(1724665017767, function(require, module, exports) {

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

}, function(modId) {var map = {"./impls":1724665017768,"./args":1724665017771,"./types":1724665017774}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017768, function(require, module, exports) {

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
__exportStar(require("./cpcl"), exports);

}, function(modId) { var map = {"./generic":1724665017769,"./cpcl":1724665017803}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017769, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.GenericCPCL = void 0;
const basic_1 = require("./basic");
class GenericCPCL extends basic_1.BasicCPCL {
    constructor(lifecycle) {
        super(lifecycle);
    }
}
exports.GenericCPCL = GenericCPCL;

}, function(modId) { var map = {"./basic":1724665017770}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017770, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.BasicCPCL = void 0;
const frame_father_1 = require("@psdk/frame-father");
const args_1 = require("../args");
const types_1 = require("../types");
class BasicCPCL extends frame_father_1.PSDK {
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
     * 一维码
     */
    bar(arg) {
        return super.push(arg);
    }
    /**
     * 画矩形边框
     */
    box(arg) {
        return super.push(arg);
    }
    /**
     * 加粗
     * @param bold true 加粗 false 不加粗
     */
    bold(bold) {
        return super.push(new args_1.CBold({ bold: bold }));
    }
    /**
     * 定位到标签(print指令之前调用)
     */
    feed(arg) {
        return super.push(arg);
    }
    /**
     * 定位到标签(可以放在print指令之后调用)
     */
    form(arg) {
        return super.push(arg);
    }
    /**
     * 打印图片
     */
    image(arg) {
        return super.push(arg);
    }
    /**
     * 文字反白
     */
    inverse(arg) {
        return super.push(arg);
    }
    /**
     * 画线(能画斜线)
     */
    line(arg) {
        return super.push(arg);
    }
    mag(arg) {
        return super.push(arg);
    }
    /**
     * 打印模式(是否定位)
     */
    pageMode(arg) {
        return super.push(arg);
    }
    /**
     * 创建打印页面大小
     */
    page(arg) {
        return super.push(arg);
    }
    /**
     * 打印
     */
    print(arg) {
        return super.push(arg !== null && arg !== void 0 ? arg : new args_1.CPrint({ mode: types_1.CMode.NORMAL }));
    }
    /**
     * 打印二维码
     */
    qrcode(arg) {
        return super.push(arg);
    }
    /**
     * 打印文本
     */
    text(arg) {
        return super.push(arg);
    }
    /**
     * 下划线
     *
     * @param underline true 画下划线 false 不画下划线
     */
    underline(underline) {
        return super.push(new args_1.CUnderLine({ underline: underline }));
    }
    /**
     * 水印
     * @param arg
     */
    waterMark(arg) {
        return super.push(arg);
    }
    /**
     * 查询打印机状态
     */
    status(arg) {
        return super.push(arg);
    }
    /**
     * 查询打印机SN
     */
    sn(arg) {
        return super.push(arg);
    }
}
exports.BasicCPCL = BasicCPCL;

}, function(modId) { var map = {"../args":1724665017771,"../types":1724665017774}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017771, function(require, module, exports) {

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
__exportStar(require("./basic"), exports);
__exportStar(require("./bold"), exports);
__exportStar(require("./box"), exports);
__exportStar(require("./feed"), exports);
__exportStar(require("./form"), exports);
__exportStar(require("./gap"), exports);
__exportStar(require("./image"), exports);
__exportStar(require("./inverse"), exports);
__exportStar(require("./line"), exports);
__exportStar(require("./mag"), exports);
__exportStar(require("./page"), exports);
__exportStar(require("./pageheight"), exports);
__exportStar(require("./pagemode"), exports);
__exportStar(require("./pagesetup"), exports);
__exportStar(require("./pagewidth"), exports);
__exportStar(require("./print"), exports);
__exportStar(require("./qrcode"), exports);
__exportStar(require("./status"), exports);
__exportStar(require("./text"), exports);
__exportStar(require("./underline"), exports);
__exportStar(require("./watermark"), exports);
__exportStar(require("./sn"), exports);

}, function(modId) { var map = {"./bar":1724665017772,"./basic":1724665017773,"./bold":1724665017782,"./box":1724665017783,"./feed":1724665017784,"./form":1724665017787,"./gap":1724665017786,"./image":1724665017789,"./inverse":1724665017790,"./line":1724665017791,"./mag":1724665017792,"./page":1724665017793,"./pageheight":1724665017794,"./pagemode":1724665017795,"./pagesetup":1724665017796,"./pagewidth":1724665017785,"./print":1724665017788,"./qrcode":1724665017797,"./status":1724665017798,"./text":1724665017799,"./underline":1724665017800,"./watermark":1724665017801,"./sn":1724665017802}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017772, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CBar = void 0;
const frame_father_1 = require("@psdk/frame-father");
const basic_1 = require("./basic");
const types_1 = require("../types");
class CBar extends basic_1.BasicCPCLArg {
    constructor(options) {
        var _a, _b, _c, _d, _e, _f, _g;
        super();
        this.x = (_a = options === null || options === void 0 ? void 0 : options.x) !== null && _a !== void 0 ? _a : 0;
        this.y = (_b = options === null || options === void 0 ? void 0 : options.y) !== null && _b !== void 0 ? _b : 0;
        this.content = (_c = options === null || options === void 0 ? void 0 : options.content) !== null && _c !== void 0 ? _c : '';
        this.lineWidth = (_d = options === null || options === void 0 ? void 0 : options.lineWidth) !== null && _d !== void 0 ? _d : 0;
        this.height = (_e = options === null || options === void 0 ? void 0 : options.height) !== null && _e !== void 0 ? _e : 0;
        this.codeType = (_f = options === null || options === void 0 ? void 0 : options.codeType) !== null && _f !== void 0 ? _f : types_1.CCodeType.CODE128;
        this.codeRotation = (_g = options.codeRotation) !== null && _g !== void 0 ? _g : types_1.CCodeRotation.ROTATION_0;
    }
    clause() {
        let code;
        switch (this.codeType) {
            case types_1.CCodeType.CODE39:
                code = new CodeTypeEntity('39', '2');
                break;
            case types_1.CCodeType.CODE128:
                code = new CodeTypeEntity('128', '2');
                break;
            case types_1.CCodeType.CODE93:
                code = new CodeTypeEntity('93', '1');
                break;
            case types_1.CCodeType.CODABAR:
                code = new CodeTypeEntity('CODABAR', '2');
                break;
            case types_1.CCodeType.EAN8:
                code = new CodeTypeEntity('EAN8', '2');
                break;
            case types_1.CCodeType.EAN13:
                code = new CodeTypeEntity('EAN13', '2');
                break;
            case types_1.CCodeType.UPCA:
                code = new CodeTypeEntity('UPCA', '2');
                break;
            case types_1.CCodeType.UPCE:
                code = new CodeTypeEntity('UPCE', '2');
                break;
            case types_1.CCodeType.I2OF5:
                code = new CodeTypeEntity('I2OF5', '2');
                break;
        }
        return frame_father_1.CPCLCommand.with(this.header())
            .appendText(this.codeRotation.toString())
            .appendText(code.type)
            .appendText(code.width)
            .appendNumber(2)
            .appendNumber(this.height)
            .appendNumber(this.x)
            .appendNumber(this.y)
            .appendText(this.content)
            .clause();
    }
    header() {
        return '';
    }
}
exports.CBar = CBar;
class CodeTypeEntity {
    constructor(type, width) {
        this.type = type;
        this.width = width;
    }
}

}, function(modId) { var map = {"./basic":1724665017773,"../types":1724665017774}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017773, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.BasicCPCLArg = void 0;
const frame_father_1 = require("@psdk/frame-father");
class BasicCPCLArg extends frame_father_1.EasyArg {
    append(arg) {
        super.append(arg);
        return this;
    }
    prepend(arg) {
        super.prepend(arg);
        return this;
    }
}
exports.BasicCPCLArg = BasicCPCLArg;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017774, function(require, module, exports) {

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
__exportStar(require("./coderotation"), exports);
__exportStar(require("./codetype"), exports);
__exportStar(require("./correctlevel"), exports);
__exportStar(require("./font"), exports);
__exportStar(require("./location"), exports);
__exportStar(require("./mode"), exports);
__exportStar(require("./rotation"), exports);

}, function(modId) { var map = {"./coderotation":1724665017775,"./codetype":1724665017776,"./correctlevel":1724665017777,"./font":1724665017778,"./location":1724665017779,"./mode":1724665017780,"./rotation":1724665017781}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017775, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CCodeRotation = void 0;
var CCodeRotation;
(function (CCodeRotation) {
    /**
     * 旋转0度
     */
    CCodeRotation["ROTATION_0"] = "B";
    /**
     * 旋转90度
     */
    CCodeRotation["ROTATION_90"] = "VB";
})(CCodeRotation = exports.CCodeRotation || (exports.CCodeRotation = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017776, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CCodeType = void 0;
/**
 * CodeType
 */
var CCodeType;
(function (CCodeType) {
    /**
     * CODE39
     */
    CCodeType[CCodeType["CODE39"] = 0] = "CODE39";
    /**
     * CODE128
     */
    CCodeType[CCodeType["CODE128"] = 1] = "CODE128";
    /**
     * CODE93
     */
    CCodeType[CCodeType["CODE93"] = 2] = "CODE93";
    /**
     * CODABAR
     */
    CCodeType[CCodeType["CODABAR"] = 3] = "CODABAR";
    /**
     * EAN8
     */
    CCodeType[CCodeType["EAN8"] = 4] = "EAN8";
    /**
     * EAN13
     */
    CCodeType[CCodeType["EAN13"] = 5] = "EAN13";
    /**
     * UPCA
     */
    CCodeType[CCodeType["UPCA"] = 6] = "UPCA";
    /**
     * UPCE
     */
    CCodeType[CCodeType["UPCE"] = 7] = "UPCE";
    /**
     * I2OF5
     */
    CCodeType[CCodeType["I2OF5"] = 8] = "I2OF5";
})(CCodeType = exports.CCodeType || (exports.CCodeType = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017777, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CCorrectLevel = void 0;
var CCorrectLevel;
(function (CCorrectLevel) {
    /**
     * 纠错等级：L
     */
    CCorrectLevel["L"] = "L";
    /**
     * 纠错等级：M
     */
    CCorrectLevel["M"] = "M";
    /**
     * 纠错等级：Q
     */
    CCorrectLevel["Q"] = "Q";
    /**
     * 纠错等级：H
     */
    CCorrectLevel["H"] = "H";
})(CCorrectLevel = exports.CCorrectLevel || (exports.CCorrectLevel = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017778, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CFont = void 0;
/**
 * font
 */
var CFont;
(function (CFont) {
    /**
     * 16点阵
     */
    CFont[CFont["TSS16"] = 0] = "TSS16";
    /**
     * 20点阵
     */
    CFont[CFont["TSS20"] = 1] = "TSS20";
    /**
     * 20点阵放大一倍
     */
    CFont[CFont["TSS20_MAX1"] = 2] = "TSS20_MAX1";
    /**
     * 24点阵
     */
    CFont[CFont["TSS24"] = 3] = "TSS24";
    /**
     * 32点阵
     */
    CFont[CFont["TSS32"] = 4] = "TSS32";
    /**
     * 24点阵放大一倍
     */
    CFont[CFont["TSS24_MAX1"] = 5] = "TSS24_MAX1";
    /**
     * 32点阵放大一倍
     */
    CFont[CFont["TSS32_MAX1"] = 6] = "TSS32_MAX1";
    /**
     * 24点阵放大两倍
     */
    CFont[CFont["TSS24_MAX2"] = 7] = "TSS24_MAX2";
    /**
     * 32点阵放大两倍
     */
    CFont[CFont["TSS32_MAX2"] = 8] = "TSS32_MAX2";
    /**
     * 28点阵放大一倍
     */
    CFont[CFont["TSS28_MAX1"] = 9] = "TSS28_MAX1";
})(CFont = exports.CFont || (exports.CFont = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017779, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CLocation = void 0;
var CLocation;
(function (CLocation) {
    /**
     * 打印结束后不定位，直接停止
     */
    CLocation[CLocation["NO_LOCATION"] = 0] = "NO_LOCATION";
    /**
     * 打印结束后定位到标签分割线，如果无缝隙，最大进纸skip个dot后停止(1mm==8dot)
     */
    CLocation[CLocation["SKIP"] = 1] = "SKIP";
})(CLocation = exports.CLocation || (exports.CLocation = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017780, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CMode = void 0;
var CMode;
(function (CMode) {
    /**
     * 正常打印，不旋转
     */
    CMode[CMode["NORMAL"] = 0] = "NORMAL";
    /**
     * 整个页面顺时针旋转180°后，再打印
     */
    CMode[CMode["HORIZONTAL"] = 1] = "HORIZONTAL";
})(CMode = exports.CMode || (exports.CMode = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017781, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CRotation = void 0;
var CRotation;
(function (CRotation) {
    /**
     * 旋转0度
     */
    CRotation["ROTATION_0"] = "";
    /**
     * 旋转90度
     */
    CRotation["ROTATION_90"] = "90";
    /**
     * 旋转180度
     */
    CRotation["ROTATION_180"] = "180";
    /**
     * 旋转270度
     */
    CRotation["ROTATION_270"] = "270";
})(CRotation = exports.CRotation || (exports.CRotation = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017782, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CBold = void 0;
const frame_father_1 = require("@psdk/frame-father");
const basic_1 = require("./basic");
class CBold extends basic_1.BasicCPCLArg {
    constructor(options) {
        var _a;
        super();
        this.bold = (_a = options === null || options === void 0 ? void 0 : options.bold) !== null && _a !== void 0 ? _a : false;
    }
    clause() {
        return frame_father_1.CPCLCommand.with(this.header())
            .appendText(this.bold ? "1" : "0")
            .clause();
    }
    header() {
        return 'SETBOLD';
    }
}
exports.CBold = CBold;

}, function(modId) { var map = {"./basic":1724665017773}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017783, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CBox = void 0;
const frame_father_1 = require("@psdk/frame-father");
const basic_1 = require("./basic");
class CBox extends basic_1.BasicCPCLArg {
    constructor(options) {
        var _a, _b, _c, _d, _e;
        super();
        this.lineWidth = (_a = options === null || options === void 0 ? void 0 : options.lineWidth) !== null && _a !== void 0 ? _a : 0;
        this.topLeftX = (_b = options === null || options === void 0 ? void 0 : options.topLeftX) !== null && _b !== void 0 ? _b : 0;
        this.topLeftY = (_c = options === null || options === void 0 ? void 0 : options.topLeftY) !== null && _c !== void 0 ? _c : 0;
        this.bottomRightX = (_d = options === null || options === void 0 ? void 0 : options.bottomRightX) !== null && _d !== void 0 ? _d : 0;
        this.bottomRightY = (_e = options === null || options === void 0 ? void 0 : options.bottomRightY) !== null && _e !== void 0 ? _e : 0;
    }
    clause() {
        if (this.topLeftX > 575) {
            this.topLeftX = 575;
        }
        if (this.bottomRightX > 575) {
            this.bottomRightX = 575;
        }
        return frame_father_1.CPCLCommand.with(this.header())
            .appendNumber(this.topLeftX)
            .appendNumber(this.topLeftY)
            .appendNumber(this.bottomRightX)
            .appendNumber(this.bottomRightY)
            .appendNumber(this.lineWidth)
            .clause();
    }
    header() {
        return 'BOX';
    }
}
exports.CBox = CBox;

}, function(modId) { var map = {"./basic":1724665017773}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017784, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CFeed = void 0;
const frame_father_1 = require("@psdk/frame-father");
const basic_1 = require("./basic");
const pagewidth_1 = require("./pagewidth");
const gap_1 = require("./gap");
const form_1 = require("./form");
const print_1 = require("./print");
const types_1 = require("../types");
class CFeed extends basic_1.BasicCPCLArg {
    clause() {
        super.append(new pagewidth_1.CPageWidth({ width: 576 }))
            .append(new gap_1.CGap())
            .append(new form_1.CForm())
            .append(new print_1.CPrint({ mode: types_1.CMode.NORMAL }));
        return frame_father_1.CPCLCommand.with(this.header()).clause();
    }
    header() {
        return '! 0 200 200 0 1';
    }
}
exports.CFeed = CFeed;

}, function(modId) { var map = {"./basic":1724665017773,"./pagewidth":1724665017785,"./gap":1724665017786,"./form":1724665017787,"./print":1724665017788,"../types":1724665017774}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017785, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CPageWidth = void 0;
const frame_father_1 = require("@psdk/frame-father");
const basic_1 = require("./basic");
class CPageWidth extends basic_1.BasicCPCLArg {
    constructor(options) {
        var _a;
        super();
        this.width = (_a = options === null || options === void 0 ? void 0 : options.width) !== null && _a !== void 0 ? _a : 0;
    }
    clause() {
        return frame_father_1.CPCLCommand.with(this.header())
            .appendNumber(this.width)
            .clause();
    }
    header() {
        return 'PAGE-WIDTH';
    }
}
exports.CPageWidth = CPageWidth;

}, function(modId) { var map = {"./basic":1724665017773}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017786, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CGap = void 0;
const frame_father_1 = require("@psdk/frame-father");
class CGap extends frame_father_1.OnlyTextHeaderArg {
    header() {
        return 'GAP-SENSE';
    }
}
exports.CGap = CGap;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017787, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CForm = void 0;
const frame_father_1 = require("@psdk/frame-father");
class CForm extends frame_father_1.OnlyTextHeaderArg {
    header() {
        return 'FORM';
    }
}
exports.CForm = CForm;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017788, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CPrint = void 0;
const frame_father_1 = require("@psdk/frame-father");
const types_1 = require("../types");
class CPrint extends frame_father_1.OnlyTextHeaderArg {
    constructor(options) {
        var _a;
        super();
        this.mode = (_a = options === null || options === void 0 ? void 0 : options.mode) !== null && _a !== void 0 ? _a : types_1.CMode.NORMAL;
    }
    header() {
        return this.mode == types_1.CMode.HORIZONTAL ? "POPRINT" : "PRINT";
    }
}
exports.CPrint = CPrint;

}, function(modId) { var map = {"../types":1724665017774}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017789, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CImage = void 0;
const basic_1 = require("./basic");
const frame_father_1 = require("@psdk/frame-father");
const frame_imageb_1 = require("@psdk/frame-imageb");
/**
 * Image
 */
class CImage extends basic_1.BasicCPCLArg {
    constructor(options) {
        var _a, _b, _c, _d, _e;
        super();
        this.x = (_a = options.x) !== null && _a !== void 0 ? _a : 0;
        this.y = (_b = options.y) !== null && _b !== void 0 ? _b : 0;
        this.compress = (_c = options.compress) !== null && _c !== void 0 ? _c : false;
        this.reverse = (_d = options.reverse) !== null && _d !== void 0 ? _d : false;
        this.threshold = (_e = options.threshold) !== null && _e !== void 0 ? _e : 190;
        this.image = options.image;
    }
    clause() {
        const processer = new frame_imageb_1.Pbita({
            command: 'cpcl',
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
        const command = frame_father_1.Commander.make().pushClause(frame_father_1.CPCLCommand.with(this.header())
            .appendNumber(eWidth)
            .appendNumber(height)
            .appendNumber(this.compress ? this.x / 8 : this.x)
            .appendNumber(this.y)
            .appendNumber(this.compress ? fbytes.length : null)
            .clause(), false)
            .pushText(" ", { newline: false })
            .pushBinary(fbytes, false)
            .newline()
            .command();
        return frame_father_1.Raw.binary(command.binary()).clause();
    }
    header() {
        return this.compress ? "ZG" : "CG";
    }
}
exports.CImage = CImage;

}, function(modId) { var map = {"./basic":1724665017773}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017790, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CInverse = void 0;
const frame_father_1 = require("@psdk/frame-father");
const basic_1 = require("./basic");
class CInverse extends basic_1.BasicCPCLArg {
    constructor(options) {
        var _a, _b, _c, _d;
        super();
        this.x = (_a = options === null || options === void 0 ? void 0 : options.x) !== null && _a !== void 0 ? _a : 0;
        this.y = (_b = options === null || options === void 0 ? void 0 : options.y) !== null && _b !== void 0 ? _b : 0;
        this.width = (_c = options === null || options === void 0 ? void 0 : options.width) !== null && _c !== void 0 ? _c : 0;
        this.height = (_d = options === null || options === void 0 ? void 0 : options.height) !== null && _d !== void 0 ? _d : 0;
    }
    clause() {
        return frame_father_1.CPCLCommand.with(this.header())
            .appendNumber(this.x)
            .appendNumber(this.y)
            .appendNumber(this.x + this.width)
            .appendNumber(this.y)
            .appendNumber(this.height)
            .clause();
    }
    header() {
        return 'INVERSE-LINE';
    }
}
exports.CInverse = CInverse;

}, function(modId) { var map = {"./basic":1724665017773}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017791, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CLine = void 0;
const frame_father_1 = require("@psdk/frame-father");
const basic_1 = require("./basic");
class CLine extends basic_1.BasicCPCLArg {
    constructor(options) {
        var _a, _b, _c, _d, _e, _f;
        super();
        this.width = (_a = options === null || options === void 0 ? void 0 : options.width) !== null && _a !== void 0 ? _a : 0;
        this.startX = (_b = options === null || options === void 0 ? void 0 : options.startX) !== null && _b !== void 0 ? _b : 0;
        this.startY = (_c = options === null || options === void 0 ? void 0 : options.startY) !== null && _c !== void 0 ? _c : 0;
        this.endX = (_d = options === null || options === void 0 ? void 0 : options.endX) !== null && _d !== void 0 ? _d : 0;
        this.endY = (_e = options === null || options === void 0 ? void 0 : options.endY) !== null && _e !== void 0 ? _e : 0;
        this.isSolidLine = (_f = options === null || options === void 0 ? void 0 : options.isSolidLine) !== null && _f !== void 0 ? _f : true;
    }
    clause() {
        return frame_father_1.CPCLCommand.with(this.header())
            .appendNumber(this.startX)
            .appendNumber(this.startY)
            .appendNumber(this.endX)
            .appendNumber(this.endY)
            .appendNumber(this.width)
            .clause();
    }
    header() {
        return this.isSolidLine ? 'LINE' : 'LPLINE';
    }
}
exports.CLine = CLine;

}, function(modId) { var map = {"./basic":1724665017773}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017792, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CMag = void 0;
const frame_father_1 = require("@psdk/frame-father");
const basic_1 = require("./basic");
const types_1 = require("../types");
class CMag extends basic_1.BasicCPCLArg {
    constructor(options) {
        var _a;
        super();
        this.font = (_a = options === null || options === void 0 ? void 0 : options.font) !== null && _a !== void 0 ? _a : types_1.CFont.TSS16;
    }
    clause() {
        let fontEntity;
        switch (this.font) {
            case types_1.CFont.TSS16:
                fontEntity = new FontEntity(1, 1, 55, 0, 16);
                break;
            case types_1.CFont.TSS20:
                fontEntity = new FontEntity(1, 1, 6, 0, 20);
                break;
            case types_1.CFont.TSS20_MAX1:
                fontEntity = new FontEntity(1, 1, 6, 0, 40);
                break;
            case types_1.CFont.TSS24:
                fontEntity = new FontEntity(1, 1, 24, 0, 24);
                break;
            case types_1.CFont.TSS32:
                fontEntity = new FontEntity(1, 1, 4, 0, 32);
                break;
            case types_1.CFont.TSS24_MAX1:
                fontEntity = new FontEntity(2, 2, 24, 0, 48);
                break;
            case types_1.CFont.TSS24_MAX2:
                fontEntity = new FontEntity(3, 3, 24, 0, 72);
                break;
            case types_1.CFont.TSS28_MAX1:
                fontEntity = new FontEntity(1, 1, 7, 3, 56);
                break;
            case types_1.CFont.TSS32_MAX1:
                fontEntity = new FontEntity(2, 2, 4, 0, 64);
                break;
            case types_1.CFont.TSS32_MAX2:
                fontEntity = new FontEntity(3, 3, 4, 0, 96);
                break;
        }
        return frame_father_1.CPCLCommand.with(this.header())
            .appendNumber(fontEntity.ex)
            .appendNumber(fontEntity.ey)
            .clause();
    }
    header() {
        return 'SETMAG';
    }
}
exports.CMag = CMag;
class FontEntity {
    constructor(ex, ey, family, size, height) {
        this.ex = ex;
        this.ey = ey;
        this.family = family;
        this.size = size;
        this.height = height;
    }
}

}, function(modId) { var map = {"./basic":1724665017773,"../types":1724665017774}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017793, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CPage = void 0;
const frame_father_1 = require("@psdk/frame-father");
const basic_1 = require("./basic");
const pageheight_1 = require("./pageheight");
const pagewidth_1 = require("./pagewidth");
class CPage extends basic_1.BasicCPCLArg {
    constructor(options) {
        var _a, _b, _c;
        super();
        this.width = (_a = options === null || options === void 0 ? void 0 : options.width) !== null && _a !== void 0 ? _a : 0;
        this.height = (_b = options === null || options === void 0 ? void 0 : options.height) !== null && _b !== void 0 ? _b : 0;
        this.copies = (_c = options === null || options === void 0 ? void 0 : options.copies) !== null && _c !== void 0 ? _c : 1;
    }
    clause() {
        super.prepend(new pageheight_1.CPageHeight({ height: this.height, copies: this.copies }));
        super.append(new pagewidth_1.CPageWidth({ width: this.width }));
        return frame_father_1.CPCLCommand.with(this.header())
            .clause();
    }
    header() {
        return '';
    }
}
exports.CPage = CPage;

}, function(modId) { var map = {"./basic":1724665017773,"./pageheight":1724665017794,"./pagewidth":1724665017785}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017794, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CPageHeight = void 0;
const frame_father_1 = require("@psdk/frame-father");
const basic_1 = require("./basic");
class CPageHeight extends basic_1.BasicCPCLArg {
    constructor(options) {
        var _a, _b;
        super();
        this.height = (_a = options === null || options === void 0 ? void 0 : options.height) !== null && _a !== void 0 ? _a : 0;
        this.copies = (_b = options === null || options === void 0 ? void 0 : options.copies) !== null && _b !== void 0 ? _b : 1;
    }
    clause() {
        return frame_father_1.CPCLCommand.with(this.header())
            .appendNumber(this.height)
            .appendNumber(this.copies)
            .clause();
    }
    header() {
        return '! 0 200 200';
    }
}
exports.CPageHeight = CPageHeight;

}, function(modId) { var map = {"./basic":1724665017773}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017795, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CPageMode = void 0;
const frame_father_1 = require("@psdk/frame-father");
const basic_1 = require("./basic");
const types_1 = require("../types");
const gap_1 = require("./gap");
const form_1 = require("./form");
class CPageMode extends basic_1.BasicCPCLArg {
    constructor(options) {
        var _a;
        super();
        this.location = (_a = options === null || options === void 0 ? void 0 : options.location) !== null && _a !== void 0 ? _a : types_1.CLocation.NO_LOCATION;
    }
    clause() {
        if (this.location > 0)
            super.prepend(new gap_1.CGap()).prepend(new form_1.CForm());
        return frame_father_1.CPCLCommand.with(this.header())
            .clause();
    }
    header() {
        return '';
    }
}
exports.CPageMode = CPageMode;

}, function(modId) { var map = {"./basic":1724665017773,"../types":1724665017774,"./gap":1724665017786,"./form":1724665017787}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017796, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CPageSetup = void 0;
const frame_father_1 = require("@psdk/frame-father");
const basic_1 = require("./basic");
const pageheight_1 = require("./pageheight");
const pagewidth_1 = require("./pagewidth");
class CPageSetup extends basic_1.BasicCPCLArg {
    constructor(options) {
        var _a, _b;
        super();
        this.pageHeight = (_a = options === null || options === void 0 ? void 0 : options.pageHeight) !== null && _a !== void 0 ? _a : 0;
        this.pageWidth = (_b = options === null || options === void 0 ? void 0 : options.pageHeight) !== null && _b !== void 0 ? _b : 0;
    }
    clause() {
        super.prepend(new pageheight_1.CPageHeight({ height: this.pageHeight }));
        super.append(new pagewidth_1.CPageWidth({ width: this.pageWidth }));
        return frame_father_1.CPCLCommand.with(this.header()).clause();
    }
    header() {
        return '';
    }
}
exports.CPageSetup = CPageSetup;

}, function(modId) { var map = {"./basic":1724665017773,"./pageheight":1724665017794,"./pagewidth":1724665017785}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017797, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CQRCode = void 0;
const frame_father_1 = require("@psdk/frame-father");
const basic_1 = require("./basic");
const types_1 = require("../types");
class CQRCode extends basic_1.BasicCPCLArg {
    constructor(options) {
        var _a, _b, _c, _d, _e, _f, _g;
        super();
        this.x = (_a = options.x) !== null && _a !== void 0 ? _a : 0;
        this.y = (_b = options.y) !== null && _b !== void 0 ? _b : 0;
        this.content = (_c = options.content) !== null && _c !== void 0 ? _c : '';
        this.codeRotation = (_d = options.codeRotation) !== null && _d !== void 0 ? _d : types_1.CCodeRotation.ROTATION_0;
        this.width = (_e = options.width) !== null && _e !== void 0 ? _e : 0;
        this.level = (_f = options.level) !== null && _f !== void 0 ? _f : types_1.CCorrectLevel.H;
        this.charset = (_g = options.charset) !== null && _g !== void 0 ? _g : 'gbk';
    }
    clause() {
        return frame_father_1.CPCLCommand.with(this.header(), this.charset)
            .appendText("3" + "\n" + this.codeRotation)
            .appendText("QR")
            .appendNumber(this.x)
            .appendNumber(this.y)
            .appendText("M")
            .appendText("2")
            .appendText("U")
            .appendText(this.width + "\n" + this.level + "A," + this.content + "\n" + "ENDQR")
            .clause();
    }
    header() {
        return 'SETQRVER';
    }
}
exports.CQRCode = CQRCode;

}, function(modId) { var map = {"./basic":1724665017773,"../types":1724665017774}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017798, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CStatus = void 0;
const frame_father_1 = require("@psdk/frame-father");
class CStatus extends frame_father_1.OnlyBinaryHeaderArg {
    constructor() {
        super();
    }
    header() {
        return new Uint8Array([0x10, 0x04, 0x05]);
    }
    newline() {
        return false;
    }
}
exports.CStatus = CStatus;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017799, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CText = void 0;
const frame_father_1 = require("@psdk/frame-father");
const basic_1 = require("./basic");
const types_1 = require("../types");
class CText extends basic_1.BasicCPCLArg {
    constructor(options) {
        var _a, _b, _c, _d, _e, _f;
        super();
        this.x = (_a = options === null || options === void 0 ? void 0 : options.x) !== null && _a !== void 0 ? _a : 0;
        this.y = (_b = options === null || options === void 0 ? void 0 : options.y) !== null && _b !== void 0 ? _b : 0;
        this.content = (_c = options === null || options === void 0 ? void 0 : options.content) !== null && _c !== void 0 ? _c : '';
        this.font = (_d = options === null || options === void 0 ? void 0 : options.font) !== null && _d !== void 0 ? _d : types_1.CFont.TSS16;
        this.rotation = (_e = options === null || options === void 0 ? void 0 : options.rotation) !== null && _e !== void 0 ? _e : types_1.CRotation.ROTATION_0;
        this.charset = (_f = options === null || options === void 0 ? void 0 : options.charset) !== null && _f !== void 0 ? _f : 'gbk';
    }
    clause() {
        let fontEntity;
        switch (this.font) {
            case types_1.CFont.TSS16:
                fontEntity = new FontEntity(1, 1, 55, 0, 16);
                break;
            case types_1.CFont.TSS20:
                fontEntity = new FontEntity(1, 1, 6, 0, 20);
                break;
            case types_1.CFont.TSS20_MAX1:
                fontEntity = new FontEntity(1, 1, 6, 0, 40);
                break;
            case types_1.CFont.TSS24:
                fontEntity = new FontEntity(1, 1, 24, 0, 24);
                break;
            case types_1.CFont.TSS32:
                fontEntity = new FontEntity(1, 1, 4, 0, 32);
                break;
            case types_1.CFont.TSS24_MAX1:
                fontEntity = new FontEntity(2, 2, 24, 0, 48);
                break;
            case types_1.CFont.TSS24_MAX2:
                fontEntity = new FontEntity(3, 3, 24, 0, 72);
                break;
            case types_1.CFont.TSS28_MAX1:
                fontEntity = new FontEntity(1, 1, 7, 3, 56);
                break;
            case types_1.CFont.TSS32_MAX1:
                fontEntity = new FontEntity(2, 2, 4, 0, 64);
                break;
            case types_1.CFont.TSS32_MAX2:
                fontEntity = new FontEntity(3, 3, 4, 0, 96);
                break;
        }
        return frame_father_1.CPCLCommand.with(this.header(), this.charset)
            .appendNumber(fontEntity.family)
            .appendNumber(fontEntity.size)
            .appendNumber(this.x)
            .appendNumber(this.y)
            .appendText(this.content)
            .clause();
    }
    header() {
        return 'T' + this.rotation;
    }
}
exports.CText = CText;
class FontEntity {
    constructor(ex, ey, family, size, height) {
        this.ex = ex;
        this.ey = ey;
        this.family = family;
        this.size = size;
        this.height = height;
    }
}

}, function(modId) { var map = {"./basic":1724665017773,"../types":1724665017774}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017800, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CUnderLine = void 0;
const frame_father_1 = require("@psdk/frame-father");
const basic_1 = require("./basic");
class CUnderLine extends basic_1.BasicCPCLArg {
    constructor(options) {
        var _a;
        super();
        this.underline = (_a = options === null || options === void 0 ? void 0 : options.underline) !== null && _a !== void 0 ? _a : false;
    }
    clause() {
        return frame_father_1.CPCLCommand.with(this.header())
            .appendText(this.underline ? "ON" : "OFF")
            .clause();
    }
    header() {
        return 'UNDERLINE';
    }
}
exports.CUnderLine = CUnderLine;

}, function(modId) { var map = {"./basic":1724665017773}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017801, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CWaterMark = void 0;
const frame_father_1 = require("@psdk/frame-father");
const basic_1 = require("./basic");
class CWaterMark extends basic_1.BasicCPCLArg {
    constructor(options) {
        var _a;
        super();
        this.value = (_a = options === null || options === void 0 ? void 0 : options.value) !== null && _a !== void 0 ? _a : 0;
    }
    clause() {
        return frame_father_1.CPCLCommand.with(this.header())
            .appendNumber(this.value)
            .clause();
    }
    header() {
        return 'WAT';
    }
}
exports.CWaterMark = CWaterMark;

}, function(modId) { var map = {"./basic":1724665017773}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017802, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CSN = void 0;
const frame_father_1 = require("@psdk/frame-father");
class CSN extends frame_father_1.OnlyBinaryHeaderArg {
    constructor() {
        super();
    }
    header() {
        return new Uint8Array([0x10, 0xff, 0xef, 0xf2]);
    }
    newline() {
        return false;
    }
}
exports.CSN = CSN;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017803, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CPCL = void 0;
const generic_1 = require("./generic");
/**
 * CPCL entrypoint
 */
class CPCL {
    /**
     * Generic cpcl command
     * @param lifecycle lifecycle
     */
    static generic(lifecycle) {
        return new generic_1.GenericCPCL(lifecycle);
    }
}
exports.CPCL = CPCL;

}, function(modId) { var map = {"./generic":1724665017769}; return __REQUIRE__(map[modId], modId); })
return __REQUIRE__(1724665017767);
})()
//miniprogram-npm-outsideDeps=["@psdk/frame-father","@psdk/frame-imageb"]
//# sourceMappingURL=index.js.map