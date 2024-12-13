module.exports = (function() {
var __MODS__ = {};
var __DEFINE__ = function(modId, func, req) { var m = { exports: {}, _tempexports: {} }; __MODS__[modId] = { status: 0, func: func, req: req, m: m }; };
var __REQUIRE__ = function(modId, source) { if(!__MODS__[modId]) return require(source); if(!__MODS__[modId].status) { var m = __MODS__[modId].m; m._exports = m._tempexports; var desp = Object.getOwnPropertyDescriptor(m, "exports"); if (desp && desp.configurable) Object.defineProperty(m, "exports", { set: function (val) { if(typeof val === "object" && val !== m._exports) { m._exports.__proto__ = val.__proto__; Object.keys(val).forEach(function (k) { m._exports[k] = val[k]; }); } m._tempexports = val }, get: function () { return m._tempexports; } }); __MODS__[modId].status = 1; __MODS__[modId].func(__MODS__[modId].req, m, m.exports); } return __MODS__[modId].m.exports; };
var __REQUIRE_WILDCARD__ = function(obj) { if(obj && obj.__esModule) { return obj; } else { var newObj = {}; if(obj != null) { for(var k in obj) { if (Object.prototype.hasOwnProperty.call(obj, k)) newObj[k] = obj[k]; } } newObj.default = obj; return newObj; } };
var __REQUIRE_DEFAULT__ = function(obj) { return obj && obj.__esModule ? obj.default : obj; };
__DEFINE__(1724665017845, function(require, module, exports) {

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
__exportStar(require("./device/adapter"), exports);
__exportStar(require("./father"), exports);
__exportStar(require("./toolkit"), exports);

}, function(modId) {var map = {"./device/adapter":1724665017846,"./father":1724665017849,"./toolkit":1724665017854}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017846, function(require, module, exports) {

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
__exportStar(require("./connected_device"), exports);
__exportStar(require("./types"), exports);

}, function(modId) { var map = {"./connected_device":1724665017847,"./types":1724665017848}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017847, function(require, module, exports) {

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
exports.FakeConnectedDevice = void 0;
/**
 * Connectec device
 */
const types_1 = require("./types");
const father_1 = require("../../father");
/**
 * Fake connected device
 */
class FakeConnectedDevice {
    origin() {
        return "FAKE-DEVICE";
    }
    connectionState() {
        return types_1.ConnectionState.CONNECTED;
    }
    deviceName() {
        return "FAKE-DEVICE";
    }
    disconnect() {
        return __awaiter(this, void 0, void 0, function* () {
        });
    }
    canRead() {
        return true;
    }
    read(options) {
        return __awaiter(this, void 0, void 0, function* () {
            return father_1.PsdkConst.EMPTY_BYTES;
        });
    }
    write(data) {
        return __awaiter(this, void 0, void 0, function* () {
            console.log('WRITE: ', data);
        });
    }
    flush() {
    }
}
exports.FakeConnectedDevice = FakeConnectedDevice;

}, function(modId) { var map = {"./types":1724665017848,"../../father":1724665017849}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017848, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.ReadOptions = exports.WroteReporter = exports.ConnectionState = void 0;
/**
 * Connection state
 */
var ConnectionState;
(function (ConnectionState) {
    /**
     * connected
     */
    ConnectionState["CONNECTED"] = "CONNECTED";
    /**
     * disconnect
     */
    ConnectionState["DISCONNECTED"] = "DISCONNECTED";
})(ConnectionState = exports.ConnectionState || (exports.ConnectionState = {}));
/**
 * Wrote reporter
 */
class WroteReporter {
    constructor(
    /**
     * Wrote is ok
     */
    ok, 
    /**
     * Wrote data
     */
    binary, 
    /**
     * control exit
     */
    controlExit, 
    /**
     * exception
     */
    exception) {
        this.ok = ok;
        this.binary = binary;
        this.controlExit = controlExit;
        this.exception = exception;
    }
}
exports.WroteReporter = WroteReporter;
/**
 * Read options
 */
class ReadOptions {
    constructor(options) {
        this.timeout = options === null || options === void 0 ? void 0 : options.timeout;
    }
}
exports.ReadOptions = ReadOptions;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017849, function(require, module, exports) {

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
__exportStar(require("./args"), exports);
__exportStar(require("./types"), exports);
__exportStar(require("./command"), exports);
__exportStar(require("./PSDK"), exports);

}, function(modId) { var map = {"./args":1724665017850,"./types":1724665017852,"./command":1724665017863,"./PSDK":1724665017871}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017850, function(require, module, exports) {

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
__exportStar(require("./arg"), exports);
__exportStar(require("./common/easy"), exports);
__exportStar(require("./common/raw"), exports);

}, function(modId) { var map = {"./arg":1724665017851,"./common/easy":1724665017862,"./common/raw":1724665017870}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017851, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.BasicArg = void 0;
const types_1 = require("../types");
class BasicArg {
    newline() {
        return types_1.PsdkConst.DEF_ENABLED_NEWLINE;
    }
}
exports.BasicArg = BasicArg;

}, function(modId) { var map = {"../types":1724665017852}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017852, function(require, module, exports) {

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
__exportStar(require("./psdk_const"), exports);
__exportStar(require("./hex_output"), exports);
__exportStar(require("./write"), exports);
__exportStar(require("./lifecycle"), exports);

}, function(modId) { var map = {"./psdk_const":1724665017853,"./hex_output":1724665017859,"./write":1724665017860,"./lifecycle":1724665017861}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017853, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.PsdkConst = void 0;
const toolkit_1 = require("../../toolkit");
const CR = '\r';
const LF = '\n';
const CRLF = `${CR}${LF}`;
/**
 * constants
 */
exports.PsdkConst = {
    DEF_CHARSET: 'gbk',
    CR,
    LF,
    CRLF,
    QUOTE: '"',
    DEF_NEWLINE_BINARY: toolkit_1.ByteKit.textToU8A(CRLF),
    DEF_AUTHORS: ['fewensa <osuni@protonmail.com>'],
    DEF_ENABLED_NEWLINE: true,
    DEF_WRITE_CHUNK_SIZE: 512,
    EMPTY_BYTES: new Uint8Array([]),
};

}, function(modId) { var map = {"../../toolkit":1724665017854}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017854, function(require, module, exports) {

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
__exportStar(require("./byte"), exports);
__exportStar(require("./pvariable"), exports);
__exportStar(require("./pcollection"), exports);
__exportStar(require("./pimage"), exports);

}, function(modId) { var map = {"./byte":1724665017855,"./pvariable":1724665017856,"./pcollection":1724665017857,"./pimage":1724665017858}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017855, function(require, module, exports) {

var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ByteKit = void 0;
// @ts-ignore
const is_js_1 = __importDefault(require("is_js"));
/**
 * Byte kit
 */
class ByteKit {
    /**
     * Text to byte
     * @param text text
     */
    static textToU8A(text) {
        if (is_js_1.default.not.truthy(text))
            return new Uint8Array([]);
        let bytes = [];
        let len, c;
        len = text.length;
        for (let i = 0; i < len; i++) {
            c = text.charCodeAt(i);
            if (c >= 0x010000 && c <= 0x10FFFF) {
                bytes.push(((c >> 18) & 0x07) | 0xF0);
                bytes.push(((c >> 12) & 0x3F) | 0x80);
                bytes.push(((c >> 6) & 0x3F) | 0x80);
                bytes.push((c & 0x3F) | 0x80);
            }
            else if (c >= 0x000800 && c <= 0x00FFFF) {
                bytes.push(((c >> 12) & 0x0F) | 0xE0);
                bytes.push(((c >> 6) & 0x3F) | 0x80);
                bytes.push((c & 0x3F) | 0x80);
            }
            else if (c >= 0x000080 && c <= 0x0007FF) {
                bytes.push(((c >> 6) & 0x1F) | 0xC0);
                bytes.push((c & 0x3F) | 0x80);
            }
            else {
                bytes.push(c & 0xFF);
            }
        }
        return new Uint8Array(bytes);
    }
}
exports.ByteKit = ByteKit;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017856, function(require, module, exports) {

var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PVariableKit = void 0;
const is_js_1 = __importDefault(require("is_js"));
class PVariableKit {
    /**
     * Replace variable
     * @param text text
     * @param variable variable
     */
    static replace(text, variable) {
        var _a;
        if (is_js_1.default.not.truthy(text))
            return text;
        if (is_js_1.default.not.truthy(variable))
            return text;
        if (text.indexOf('{{') < 0 && text.indexOf('}}') < 0)
            return text;
        const regx = /[\\]?\{\{(?<varx>.*?)}}/gm;
        const tmpMark = '__THIS_IS_MAGIC_MARK_FOR_HACK_REGEX_MATCH__';
        while (true) {
            const match = regx.exec(text);
            if (match == null)
                break;
            const originDefined = match[0];
            const originVarx = originDefined.replace('{{', '')
                .replace('}}', '');
            const varName = originVarx.trim();
            const varValue = (_a = variable.get(varName)) !== null && _a !== void 0 ? _a : '';
            if (originDefined.startsWith('\\')) {
                const tmpDefined = originDefined.replace('\\{{', tmpMark);
                text = text.replace(originDefined, tmpDefined);
                continue;
            }
            text = text.replace(originDefined, varValue);
        }
        text = text.replace(new RegExp(tmpMark, 'g'), '{{');
        return text;
    }
}
exports.PVariableKit = PVariableKit;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017857, function(require, module, exports) {

var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.CollectionKit = void 0;
const is_js_1 = __importDefault(require("is_js"));
/**
 * Collection kit
 */
class CollectionKit {
    /**
     * Split array
     *
     * @param colls collections
     * @param size  The size of result array
     * @return List
     */
    static split(colls, size) {
        if (is_js_1.default.empty(colls))
            return [];
        if (size <= 0)
            throw new Error('The size must > 0');
        const rets = [];
        let items = [];
        for (const coll of colls) {
            items.push(coll);
            if (size == items.length) {
                rets.push(items);
                items = [];
            }
        }
        if (0 != items.length)
            rets.push(items);
        return rets;
    }
    /**
     * Part array
     *
     * @param colls collections
     * @param parts Part length
     * @return List
     */
    static parts(colls, parts) {
        if (is_js_1.default.empty(colls)) {
            return [];
        }
        if (parts <= 0)
            throw new Error('The parts length must > 0');
        if (colls.length <= parts) {
            return [colls];
        }
        const rets = [];
        let items = [];
        const pnum = Math.floor(colls.length / parts);
        for (const coll of colls) {
            items.push(coll);
            if (items.length == pnum) {
                rets.push(items);
                if (rets.length < parts)
                    items = [];
            }
        }
        return rets;
    }
}
exports.CollectionKit = CollectionKit;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017858, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.ImageKit = void 0;
/**
 * Image kit
 */
class ImageKit {
    /**
     * process image
     * @param canvas canvas
     * @param width width
     * @param height height
     */
    static processImage(canvas, width, height) {
        const ctx = canvas.getContext('2d');
        let eWidth = Math.floor((width % 8 === 0) ? (width / 8) : (width / 8 + 1));
        let currentHeight = 0;
        let index = 0;
        const area = height * eWidth;
        const bytes = []; // the bytes length is equals `area`
        for (let b1 = 0; b1 < area; b1++) {
            bytes[b1] = 0;
        }
        const imgData = ctx.getImageData(0, 0, canvas.width, canvas.height);
        while (currentHeight < height) {
            // let rowData = []; // the row data length is image height
            let eightBitIndex = 0;
            for (let x = 0; x < width; x++) {
                eightBitIndex++;
                if (eightBitIndex > 8) {
                    eightBitIndex = 1;
                    index++;
                }
                const n = 1 << 8 - eightBitIndex;
                // const pixel = ctx.getImageData(x, currentHeight, 1, 1);
                const pixels = ImageKit.fastExtractPixel(imgData, x, currentHeight, 1, 1);
                const pixel = pixels[0];
                // const rgba = pixel.data;
                const red = pixel[0];
                const green = pixel[1];
                const blue = pixel[2];
                if ((red + green + blue) / 3 < 128) {
                    bytes[index] = (bytes[index] | n);
                }
            }
            index = eWidth * (currentHeight + 1);
            currentHeight += 1;
        }
        return new Uint8Array(bytes);
    }
    static fastExtractPixel(imageData, x, y, w, h) {
        let i, j;
        let result = [];
        let r, g, b, a;
        const data = imageData.data;
        for (j = 0; j < h; j++) {
            let idx = (x + (y + j) * imageData.width) * 4; // get left most byte index for row at y + j
            for (i = 0; i < w; i++) {
                r = data[idx++];
                g = data[idx++];
                b = data[idx++];
                a = data[idx++];
                // do the processing
                result.push([r, g, b, a]);
            }
        }
        return result;
    }
}
exports.ImageKit = ImageKit;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017859, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.HexOutput = void 0;
const DEF_MAX_LENGTH_OF_LINE = 32;
/**
 * hex output
 */
class HexOutput {
    // private format: boolean;
    //
    // private spacing: boolean;
    //
    // private maxLengthOfLine: number = DEF_MAX_LENGTH_OF_LINE;
    constructor(
    /**
     * Is format
     */
    enableFormat, 
    /**
     * Enable spacing between byte
     */
    spacing, 
    /**
     * Max length of line
     */
    maxLengthOfLine = DEF_MAX_LENGTH_OF_LINE) {
        this.enableFormat = enableFormat;
        this.spacing = spacing;
        this.maxLengthOfLine = maxLengthOfLine;
    }
    static def() {
        return new HexOutput(false, false, DEF_MAX_LENGTH_OF_LINE);
    }
    static simple(format = true) {
        return new HexOutput(format, true, DEF_MAX_LENGTH_OF_LINE);
    }
    static formatWithMaxLength(maxLengthOfLine) {
        return new HexOutput(true, true, maxLengthOfLine);
    }
    /**
     * Format binary
     */
    format(binary) {
        // const hex = toHex(binary);
        const hex = Array.from(binary, function (byte) {
            return ('0' + (byte & 0xFF).toString(16)).slice(-2);
        }).join('');
        if (!this.enableFormat) {
            return hex;
        }
        let fmted = '';
        const textLength = hex.length;
        let lineIndex = 0;
        for (let ix = 0; ix < textLength; ix++) {
            const seq = ix + 1;
            const v = hex[ix];
            fmted += v;
            if (seq % 2 == 0 && this.spacing) {
                if (seq < textLength) {
                    if (lineIndex + 1 < this.maxLengthOfLine) {
                        fmted += ' ';
                    }
                    lineIndex += 1;
                }
            }
            if (lineIndex >= this.maxLengthOfLine) {
                fmted += '\n';
                lineIndex = 0;
            }
        }
        return fmted;
    }
}
exports.HexOutput = HexOutput;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017860, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.WriteControl = exports.DataWrote = exports.DataWrite = exports.IDataWriteCallback = exports.WriteOptions = void 0;
const psdk_const_1 = require("./psdk_const");
/**
 * Write to device options
 */
class WriteOptions {
    constructor(
    /**
     * Enable data splitting
     */
    enableChunkWrite = true, 
    /**
     * Part size
     */
    chunkSize = psdk_const_1.PsdkConst.DEF_WRITE_CHUNK_SIZE, 
    /**
     * Data write callback
     */
    callback) {
        this.enableChunkWrite = enableChunkWrite;
        this.chunkSize = chunkSize;
        this.callback = callback;
    }
    static def() {
        return new WriteOptions(true, psdk_const_1.PsdkConst.DEF_WRITE_CHUNK_SIZE, undefined);
    }
}
exports.WriteOptions = WriteOptions;
/**
 * Data write callback
 */
class IDataWriteCallback {
    failed(data, exception) {
        console.error(`Write data failed: ${exception.message}`);
    }
}
exports.IDataWriteCallback = IDataWriteCallback;
/**
 * Data write
 */
class DataWrite {
    constructor(
    /**
     * Wrote binary
     */
    binary, 
    /**
     * Write current times
     */
    currentTimes, 
    /**
     * Write total times
     */
    totalTimes) {
        this.binary = binary;
        this.currentTimes = currentTimes;
        this.totalTimes = totalTimes;
    }
}
exports.DataWrite = DataWrite;
/**
 * Data wrote
 */
class DataWrote extends DataWrite {
}
exports.DataWrote = DataWrote;
/**
 * Write control
 */
var WriteControl;
(function (WriteControl) {
    WriteControl["CONTINUE"] = "CONTINUE";
    WriteControl["STOP"] = "STOP";
})(WriteControl = exports.WriteControl || (exports.WriteControl = {}));

}, function(modId) { var map = {"./psdk_const":1724665017853}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017861, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.Lifecycle = void 0;
class Lifecycle {
    constructor(
    /**
     * Connected device
     */
    connectedDevice) {
        this.connectedDevice = connectedDevice;
    }
}
exports.Lifecycle = Lifecycle;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017862, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.OnlyTextHeaderArg = exports.OnlyBinaryHeaderArg = exports.EasyArg = void 0;
const arg_1 = require("../arg");
const command_1 = require("../../command");
/**
 * Easy argument abstract class
 */
class EasyArg extends arg_1.BasicArg {
    constructor() {
        super();
        this.prependClauses = [];
        this.appendClauses = [];
    }
    /**
     * Append another argument for this clause
     * @param arg
     */
    append(arg) {
        this.appendClauses.push(...arg.clauses());
        return this;
    }
    /**
     * Prepend another argument for this clause
     * @param arg
     */
    prepend(arg) {
        this.prependClauses.push(...arg.clauses());
        return this;
    }
    /**
     * Get current command clauses
     */
    clauses() {
        const clause = this.clause();
        const currentClauses = [];
        if (clause.type !== command_1.ClauseType.NONE) {
            currentClauses.push(clause);
            if (this.newline()) {
                currentClauses.push(command_1.CommandClause.newline());
            }
        }
        return [
            ...this.prependClauses,
            ...currentClauses,
            ...this.appendClauses,
        ];
    }
    clear() {
        this.prependClauses.splice(0, this.prependClauses.length);
        this.appendClauses.splice(0, this.appendClauses.length);
    }
}
exports.EasyArg = EasyArg;
class OnlyBinaryHeaderArg extends EasyArg {
    append(arg) {
        super.append(arg);
        return this;
    }
    prepend(arg) {
        super.prepend(arg);
        return this;
    }
    clause() {
        return command_1.CommandClause.binary(this.header());
    }
    newline() {
        return false;
    }
}
exports.OnlyBinaryHeaderArg = OnlyBinaryHeaderArg;
class OnlyTextHeaderArg extends EasyArg {
    append(arg) {
        super.append(arg);
        return this;
    }
    prepend(arg) {
        super.prepend(arg);
        return this;
    }
    clause() {
        return command_1.CommandClause.text(this.header());
    }
}
exports.OnlyTextHeaderArg = OnlyTextHeaderArg;

}, function(modId) { var map = {"../arg":1724665017851,"../../command":1724665017863}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017863, function(require, module, exports) {

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
__exportStar(require("./print/command"), exports);
__exportStar(require("./print/commander"), exports);
__exportStar(require("./print/command_clause"), exports);
__exportStar(require("./single/appendat"), exports);
__exportStar(require("./single/binary_command"), exports);
__exportStar(require("./single/single_command"), exports);

}, function(modId) { var map = {"./print/command":1724665017864,"./print/commander":1724665017866,"./print/command_clause":1724665017865,"./single/appendat":1724665017867,"./single/binary_command":1724665017868,"./single/single_command":1724665017869}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017864, function(require, module, exports) {

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
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.DefaultCommand = exports.BasicCommand = void 0;
/**
 * All printer sdk command interface
 */
const types_1 = require("../../types");
const js_base64_1 = require("js-base64");
const command_clause_1 = require("./command_clause");
const toolkit_1 = require("../../../toolkit");
const iconv = __importStar(require("iconv-lite"));
class BasicCommand {
    base64() {
        return js_base64_1.Base64.fromUint8Array(this.binary());
    }
}
exports.BasicCommand = BasicCommand;
class DefaultCommand extends BasicCommand {
    constructor(clauses, variable) {
        var _a, _b;
        super();
        let bytes = [];
        for (const clause of clauses) {
            switch (clause.type) {
                case command_clause_1.ClauseType.TEXT:
                    const t = toolkit_1.PVariableKit.replace(clause.text, variable);
                    //# use gbk encoding
                    const t_buffer = iconv.encode(t, (_a = clause.charset) !== null && _a !== void 0 ? _a : types_1.PsdkConst.DEF_CHARSET);
                    const t_binary = Array.prototype.slice.call(t_buffer, 0);
                    bytes = bytes.concat(t_binary);
                    //# use utf8 encoding
                    // const t_binary = ByteKit.textToU8A(t)
                    // const array = Array.from(t_binary)
                    // bytes.push(...array);
                    break;
                case command_clause_1.ClauseType.NEWLINE:
                case command_clause_1.ClauseType.BINARY:
                    const b = Array.from((_b = clause.binary) !== null && _b !== void 0 ? _b : types_1.PsdkConst.EMPTY_BYTES);
                    bytes = bytes.concat(b);
                    break;
            }
        }
        this.bytes = new Uint8Array(bytes);
    }
    binary() {
        return this.bytes;
    }
    hex(output) {
        return (output !== null && output !== void 0 ? output : types_1.HexOutput.def()).format(this.binary());
    }
    string(charset) {
        const buffer = Array.from(this.binary());
        // @ts-ignore
        return iconv.decode(buffer, charset !== null && charset !== void 0 ? charset : types_1.PsdkConst.DEF_CHARSET);
    }
}
exports.DefaultCommand = DefaultCommand;

}, function(modId) { var map = {"../../types":1724665017852,"./command_clause":1724665017865,"../../../toolkit":1724665017854}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017865, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.CommandClause = exports.ClauseType = void 0;
const types_1 = require("../../types");
var ClauseType;
(function (ClauseType) {
    ClauseType["TEXT"] = "TEXT";
    ClauseType["BINARY"] = "BINARY";
    ClauseType["NEWLINE"] = "NEWLINE";
    ClauseType["NONE"] = "NONE";
})(ClauseType = exports.ClauseType || (exports.ClauseType = {}));
class CommandClause {
    constructor(type, text, charset, binary) {
        this._type = type;
        this._text = text;
        this._charset = charset;
        this._binary = binary;
    }
    static text(command, charset = types_1.PsdkConst.DEF_CHARSET) {
        return new CommandClause(ClauseType.TEXT, command, charset, undefined);
    }
    static binary(binary) {
        return new CommandClause(ClauseType.BINARY, undefined, undefined, binary);
    }
    static newline() {
        return new CommandClause(ClauseType.NEWLINE, undefined, undefined, types_1.PsdkConst.DEF_NEWLINE_BINARY);
    }
    static none() {
        return new CommandClause(ClauseType.NONE, undefined, undefined, undefined);
    }
    get type() {
        return this._type;
    }
    get text() {
        return this._text;
    }
    get charset() {
        return this._charset;
    }
    get binary() {
        return this._binary;
    }
}
exports.CommandClause = CommandClause;

}, function(modId) { var map = {"../../types":1724665017852}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017866, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.Commander = void 0;
const command_clause_1 = require("./command_clause");
const types_1 = require("../../types");
const command_1 = require("./command");
/**
 * Command builder
 */
class Commander {
    constructor() {
        this.clauses = [];
        this._variable = new Map();
    }
    /**
     * Make a commander
     */
    static make() {
        return new Commander();
    }
    /**
     * Push a text command
     * @param command command
     * @param options Options: { newline: newline, charset: charset }
     */
    pushText(command, options) {
        var _a, _b;
        if (command.startsWith(types_1.PsdkConst.CRLF)) {
            command = command.substring(2);
        }
        const clause = command_clause_1.CommandClause.text(command, (_a = options === null || options === void 0 ? void 0 : options.charset) !== null && _a !== void 0 ? _a : types_1.PsdkConst.DEF_CHARSET);
        return this.pushClause(clause, (_b = options === null || options === void 0 ? void 0 : options.newline) !== null && _b !== void 0 ? _b : types_1.PsdkConst.DEF_ENABLED_NEWLINE);
    }
    /**
     * Push binary command
     * @param command Command
     * @param newline Add new line for this command
     */
    pushBinary(command, newline) {
        const clause = command_clause_1.CommandClause.binary(command);
        return this.pushClause(clause, newline !== null && newline !== void 0 ? newline : types_1.PsdkConst.DEF_ENABLED_NEWLINE);
    }
    /**
     * Push clause
     * @param clause Command clause object
     * @param newline Add new line for this command
     */
    pushClause(clause, newline) {
        this.clauses.push(clause);
        if (newline !== null && newline !== void 0 ? newline : types_1.PsdkConst.DEF_ENABLED_NEWLINE) {
            this.clauses.push(command_clause_1.CommandClause.newline());
        }
        return this;
    }
    /**
     * Push multiple clause
     * @param clauses
     */
    pushClauses(clauses) {
        clauses.forEach(item => this.pushClause(item, false));
        return this;
    }
    /**
     * Push arg
     * @param arg arg
     */
    pushArg(arg) {
        this.pushClauses(arg.clauses());
        return this;
    }
    /**
     * Add newline
     */
    newline() {
        const clause = command_clause_1.CommandClause.newline();
        return this.pushClause(clause, false);
    }
    /**
     * Add a new variable
     * @param name name
     * @param value value
     */
    variable(name, value) {
        this._variable.set(name, value);
        return this;
    }
    /**
     * Clear all commands
     */
    clear() {
        this.clauses.splice(0, this.clauses.length);
        this._variable.clear();
        return this;
    }
    /**
     * Get command
     */
    command() {
        return new command_1.DefaultCommand(this.clauses, this._variable);
    }
}
exports.Commander = Commander;

}, function(modId) { var map = {"./command_clause":1724665017865,"../../types":1724665017852,"./command":1724665017864}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017867, function(require, module, exports) {

var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.TextAppendat = exports.Appendat = void 0;
const is_js_1 = __importDefault(require("is_js"));
class Appendat {
    constructor(argument, condition, callback) {
        this._argument = argument;
        this._condition = condition;
        this._callback = callback;
    }
    get condition() {
        return this._condition;
    }
    callback(callback) {
        this._callback = callback;
        return this;
    }
    quote() {
        return this;
    }
    argument() {
        if (is_js_1.default.not.truthy(this._callback))
            return this._argument;
        if (is_js_1.default.not.truthy(this._argument))
            return undefined;
        return this._callback.callback(this._argument);
    }
}
exports.Appendat = Appendat;
class TextAppendat extends Appendat {
    constructor(argument, condition, callback) {
        super(argument, condition !== null && condition !== void 0 ? condition : true, callback);
        this._quote = false;
    }
    /**
     * Create new text appendat
     * @param argument argument
     * @param options options: { condition: condition for this arg, callback: value callback }
     */
    static create(argument, options) {
        var _a;
        return new TextAppendat(argument, (_a = options === null || options === void 0 ? void 0 : options.condition) !== null && _a !== void 0 ? _a : true, new class {
            callback(data) {
                const cb = options === null || options === void 0 ? void 0 : options.callback;
                if (cb) {
                    return cb(data);
                }
                return data;
            }
        });
    }
    callback(callback) {
        super.callback(callback);
        return this;
    }
    quote() {
        this._quote = true;
        return this;
    }
    argument() {
        const arg = super.argument();
        if (is_js_1.default.not.truthy(arg))
            return this._quote ? '""' : '';
        if (this._quote) {
            return `"${arg}"`;
        }
        return arg;
    }
}
exports.TextAppendat = TextAppendat;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017868, function(require, module, exports) {

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
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.BinaryCommand = void 0;
/**
 * Binary command
 */
const types_1 = require("../../types");
const iconv = __importStar(require("iconv-lite"));
const command_clause_1 = require("../print/command_clause");
class BinaryCommand {
    constructor(binary) {
        this.binary = binary !== null && binary !== void 0 ? binary : [];
    }
    static make() {
        return new BinaryCommand();
    }
    static with(u8a) {
        const b = Array.from(u8a);
        return new BinaryCommand(b);
    }
    appendNumber(num) {
        this.binary.push(num);
        return this;
    }
    appendText(text, charset) {
        const encoding = (charset !== null && charset !== void 0 ? charset : types_1.PsdkConst.DEF_CHARSET).toLowerCase();
        const binary = iconv.encode(text, encoding);
        this.binary.push(...binary);
        return this;
    }
    appendU8A(u8a) {
        const b = Array.from(u8a);
        this.binary = this.binary.concat(b);
        return this;
    }
    output() {
        return new Uint8Array(this.binary);
    }
    clause() {
        const output = this.output();
        return command_clause_1.CommandClause.binary(output);
    }
}
exports.BinaryCommand = BinaryCommand;

}, function(modId) { var map = {"../../types":1724665017852,"../print/command_clause":1724665017865}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017869, function(require, module, exports) {

var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.TSPLCommand = exports.CPCLCommand = exports.SingleCommand = void 0;
const is_js_1 = __importDefault(require("is_js"));
/**
 * Single Command
 */
const appendat_1 = require("./appendat");
const command_clause_1 = require("../print/command_clause");
class SingleCommand {
    constructor(symbolAfterHeader, symbolBetweenArguments, charset) {
        this._arguments = [];
        this._symbolAfterHeader = symbolAfterHeader;
        this._symbolBetweenArguments = symbolBetweenArguments;
        this._charset = charset;
    }
    get getHeader() {
        return this._header;
    }
    get symbolAfterHeader() {
        return this._symbolAfterHeader;
    }
    get symbolBetweenArguments() {
        return this._symbolBetweenArguments;
    }
    header(header) {
        this._header = header;
        return this;
    }
    get charset() {
        return this._charset;
    }
    append(appendat) {
        if (!appendat.condition)
            return this;
        const argument = appendat.argument();
        if (is_js_1.default.not.truthy(argument))
            return this;
        this._arguments.push(argument);
        return this;
    }
    arguments() {
        return this._arguments;
    }
}
exports.SingleCommand = SingleCommand;
class BasicStringSingleCommand extends SingleCommand {
    constructor(symbolAfterHeader, symbolBetweenArguments, charset) {
        super(symbolAfterHeader, symbolBetweenArguments, charset);
    }
    append(appendat) {
        const argument = appendat.argument();
        if (is_js_1.default.not.truthy(argument))
            return this;
        if (argument == '')
            return this;
        super.append(appendat);
        return this;
    }
    appendText(text) {
        return this.append(appendat_1.TextAppendat.create(text !== null && text !== void 0 ? text : '', {}));
    }
    appendNumber(num) {
        if (isNaN(num))
            return this;
        return this.append(appendat_1.TextAppendat.create((num !== null && num !== void 0 ? num : '').toString(), {}));
    }
    output() {
        let ret = '';
        if (is_js_1.default.truthy(super.getHeader)) {
            ret += super.getHeader;
            ret += super.symbolAfterHeader;
        }
        const args = super.arguments();
        const len = args.length;
        let seq = 0;
        for (const arg of args) {
            seq += 1;
            if (is_js_1.default.not.truthy(arg))
                continue;
            ret += arg;
            if (seq < len) {
                ret += super.symbolBetweenArguments;
            }
        }
        return ret;
    }
    clause() {
        const output = this.output();
        if (is_js_1.default.not.truthy(output)) {
            return command_clause_1.CommandClause.none();
        }
        return command_clause_1.CommandClause.text(output, super.charset);
    }
}
class CPCLCommand extends BasicStringSingleCommand {
    constructor(header, charset) {
        super(' ', ' ', charset);
        super.header(header);
    }
    static with(header, charset) {
        return new CPCLCommand(header, charset);
    }
    append(appendat) {
        super.append(appendat);
        return this;
    }
    appendText(text) {
        super.appendText(text);
        return this;
    }
    appendNumber(num) {
        super.appendNumber(num);
        return this;
    }
}
exports.CPCLCommand = CPCLCommand;
class TSPLCommand extends BasicStringSingleCommand {
    constructor(header, charset) {
        super(' ', ',', charset);
        super.header(header);
    }
    static with(header, charset) {
        return new TSPLCommand(header, charset);
    }
    append(appendat) {
        super.append(appendat);
        return this;
    }
    appendText(text) {
        super.appendText(text);
        return this;
    }
    appendNumber(num) {
        super.appendNumber(num);
        return this;
    }
}
exports.TSPLCommand = TSPLCommand;

}, function(modId) { var map = {"./appendat":1724665017867,"../print/command_clause":1724665017865}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017870, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.RawMode = exports.Raw = void 0;
const easy_1 = require("./easy");
const command_1 = require("../../command");
const types_1 = require("../../types");
class Raw extends easy_1.EasyArg {
    constructor() {
        super();
        this._newline = types_1.PsdkConst.DEF_ENABLED_NEWLINE;
    }
    static text(text, options) {
        var _a, _b;
        const raw = new Raw();
        raw._mode = RawMode.TEXT;
        raw._text = text;
        raw._charset = (_a = options === null || options === void 0 ? void 0 : options.charset) !== null && _a !== void 0 ? _a : types_1.PsdkConst.DEF_CHARSET;
        raw._newline = (_b = options === null || options === void 0 ? void 0 : options.newline) !== null && _b !== void 0 ? _b : types_1.PsdkConst.DEF_ENABLED_NEWLINE;
        return raw;
    }
    static binary(binary, options) {
        var _a, _b;
        const raw = new Raw();
        raw._mode = RawMode.BINARY;
        raw._binary = binary;
        raw._charset = (_a = options === null || options === void 0 ? void 0 : options.charset) !== null && _a !== void 0 ? _a : types_1.PsdkConst.DEF_CHARSET;
        raw._newline = (_b = options === null || options === void 0 ? void 0 : options.newline) !== null && _b !== void 0 ? _b : types_1.PsdkConst.DEF_ENABLED_NEWLINE;
        return raw;
    }
    append(arg) {
        super.append(arg);
        return this;
    }
    prepend(arg) {
        super.prepend(arg);
        return this;
    }
    clause() {
        let clause;
        switch (this._mode) {
            case RawMode.TEXT:
                clause = command_1.CommandClause.text(this._text, this._charset);
                break;
            case RawMode.BINARY:
                clause = command_1.CommandClause.binary(this._binary);
                break;
            default:
                clause = command_1.CommandClause.none();
                break;
        }
        return clause;
    }
    header() {
        return types_1.PsdkConst.EMPTY_BYTES;
    }
    newline() {
        return this._newline;
    }
}
exports.Raw = Raw;
var RawMode;
(function (RawMode) {
    RawMode["BINARY"] = "BINARY";
    RawMode["TEXT"] = "TEXT";
})(RawMode = exports.RawMode || (exports.RawMode = {}));

}, function(modId) { var map = {"./easy":1724665017862,"../../command":1724665017863,"../../types":1724665017852}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017871, function(require, module, exports) {

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
exports.PSDK = void 0;
const types_1 = require("./types");
const write_operation_1 = require("./device/write_operation");
class PSDK {
    /**
     * sdk version
     */
    sversion() {
        return '0.2.67';
    }
    /**
     * authors
     */
    authors() {
        return types_1.PsdkConst.DEF_AUTHORS;
    }
    /**
     * Push raw command
     * @param raw raw
     */
    raw(raw) {
        this.commander().pushArg(raw);
        return this;
    }
    /**
     * Put variable
     * @param name name
     * @param value value
     */
    variable(name, value) {
        this.commander().variable(name, value);
        return this;
    }
    /**
     * get command
     */
    command() {
        return this.commander().command();
    }
    /**
     * Clear command
     */
    clear() {
        this.commander().clear();
        return this;
    }
    /**
     * Write data to device
     */
    write(options) {
        return __awaiter(this, void 0, void 0, function* () {
            const connectedDevice = this.connectedDevice();
            if (!connectedDevice)
                throw Error('It\'s seems you missing to set connectedDevice');
            options = options !== null && options !== void 0 ? options : types_1.WriteOptions.def();
            const command = this.command();
            const binary = command.binary();
            const operation = new write_operation_1.DataWriteOperation(options, binary, connectedDevice);
            const reporter = yield operation.write();
            this.clear();
            return reporter;
        });
    }
    /**
     * Newline command
     */
    newline() {
        this.commander().newline();
        return this;
    }
    /**
     * Push command
     * @param command
     */
    push(command) {
        this.commander().pushArg(command);
        return this;
    }
}
exports.PSDK = PSDK;

}, function(modId) { var map = {"./types":1724665017852,"./device/write_operation":1724665017872}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1724665017872, function(require, module, exports) {

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
exports.DataWriteOperation = void 0;
/**
 * Data write operation
 */
const types_1 = require("../types");
const adapter_1 = require("../../device/adapter");
const toolkit_1 = require("../../toolkit");
class DataWriteOperation {
    constructor(
    /**
     * Write options
     * @private
     */
    options, 
    /**
     * Write binary
     * @private
     */
    binary, 
    /**
     * Connected device
     * @private
     */
    connectedDevice) {
        this.options = options;
        this.binary = binary;
        this.connectedDevice = connectedDevice;
    }
    write() {
        return __awaiter(this, void 0, void 0, function* () {
            if (!this.options.enableChunkWrite) {
                const reporter = yield this.writData(this.binary);
                this.doCallback(reporter, this.binary, 1, 1);
                return reporter;
            }
            const writeData = Array.from(this.binary);
            const parts = toolkit_1.CollectionKit.split(writeData, this.options.chunkSize);
            const totalTimes = parts.length;
            let currentTimes = 0;
            for (const part of parts) {
                currentTimes += 1;
                const partBinary = new Uint8Array(part);
                const reporter = yield this.writData(partBinary);
                const control = this.doCallback(reporter, partBinary, currentTimes, totalTimes);
                if (control == types_1.WriteControl.STOP) {
                    reporter.controlExit = true;
                    return reporter;
                }
                if (!reporter.ok) {
                    return reporter;
                }
            }
            return new adapter_1.WroteReporter(true, this.binary, false);
        });
    }
    doCallback(reporter, binary, currentTimes, totalTimes) {
        const callback = this.options.callback;
        if (!callback)
            return types_1.WriteControl.CONTINUE;
        const dataWrote = new types_1.DataWrote(binary, currentTimes, totalTimes);
        if (reporter.ok) {
            return callback.success(dataWrote);
        }
        callback.failed(dataWrote, reporter.exception);
        return types_1.WriteControl.STOP;
    }
    writData(binary) {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                yield this.connectedDevice.write(binary);
                return new adapter_1.WroteReporter(true, binary, false);
            }
            catch (e) {
                return new adapter_1.WroteReporter(false, binary, false, e);
            }
        });
    }
}
exports.DataWriteOperation = DataWriteOperation;

}, function(modId) { var map = {"../types":1724665017852,"../../device/adapter":1724665017846,"../../toolkit":1724665017854}; return __REQUIRE__(map[modId], modId); })
return __REQUIRE__(1724665017845);
})()
//miniprogram-npm-outsideDeps=["is_js","js-base64","iconv-lite"]
//# sourceMappingURL=index.js.map