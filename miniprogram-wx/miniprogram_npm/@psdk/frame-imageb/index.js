module.exports = (function() {
var __MODS__ = {};
var __DEFINE__ = function(modId, func, req) { var m = { exports: {}, _tempexports: {} }; __MODS__[modId] = { status: 0, func: func, req: req, m: m }; };
var __REQUIRE__ = function(modId, source) { if(!__MODS__[modId]) return require(source); if(!__MODS__[modId].status) { var m = __MODS__[modId].m; m._exports = m._tempexports; var desp = Object.getOwnPropertyDescriptor(m, "exports"); if (desp && desp.configurable) Object.defineProperty(m, "exports", { set: function (val) { if(typeof val === "object" && val !== m._exports) { m._exports.__proto__ = val.__proto__; Object.keys(val).forEach(function (k) { m._exports[k] = val[k]; }); } m._tempexports = val }, get: function () { return m._tempexports; } }); __MODS__[modId].status = 1; __MODS__[modId].func(__MODS__[modId].req, m, m.exports); } return __MODS__[modId].m.exports; };
var __REQUIRE_WILDCARD__ = function(obj) { if(obj && obj.__esModule) { return obj; } else { var newObj = {}; if(obj != null) { for(var k in obj) { if (Object.prototype.hasOwnProperty.call(obj, k)) newObj[k] = obj[k]; } } newObj.default = obj; return newObj; } };
var __REQUIRE_DEFAULT__ = function(obj) { return obj && obj.__esModule ? obj.default : obj; };
__DEFINE__(1715917494049, function(require, module, exports) {

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
__exportStar(require("./process"), exports);

}, function(modId) {var map = {"./process":1715917494050}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494050, function(require, module, exports) {

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
__exportStar(require("./process"), exports);
__exportStar(require("./impls/gray"), exports);
__exportStar(require("./impls/reverse"), exports);
__exportStar(require("./impls/threshold"), exports);
__exportStar(require("./pbit/pbita"), exports);
__exportStar(require("./basic/threshold"), exports);

}, function(modId) { var map = {"./process":1715917494051,"./impls/gray":1715917494052,"./impls/reverse":1715917494055,"./impls/threshold":1715917494056,"./pbit/pbita":1715917494058,"./basic/threshold":1715917494057}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494051, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.ImagebProcesser = void 0;
class ImagebProcesser {
}
exports.ImagebProcesser = ImagebProcesser;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494052, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.GrayscaleImage = void 0;
const process_1 = require("../process");
const types_1 = require("../../types");
const tools_1 = require("../../tools");
class GrayscaleImage extends process_1.ImagebProcesser {
    constructor(options) {
        super();
        this._processer = options === null || options === void 0 ? void 0 : options._processer;
    }
    process(input) {
        let result = tools_1.ImagebTool.convertGreyImg(input);
        if (this._processer == null) {
            return new types_1.ProcessedResult({
                origin: input,
                result: new types_1.ProcessedImage({ data: result, width: result.width, height: result.height })
            });
        }
        return this._processer.process(result);
    }
}
exports.GrayscaleImage = GrayscaleImage;

}, function(modId) { var map = {"../process":1715917494051,"../../types":1715917494053,"../../tools":1715917494054}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494053, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.ThresholdValueMode = exports.ProcessedImage = exports.ProcessedResult = void 0;
class ProcessedResult {
    constructor(options) {
        this.origin = options.origin;
        this.result = options.result;
        this.message = options.message;
    }
}
exports.ProcessedResult = ProcessedResult;
class ProcessedImage {
    constructor(options) {
        this.data = options.data;
        this.width = options.width;
        this.height = options.height;
        this.bytes = options.bytes;
    }
}
exports.ProcessedImage = ProcessedImage;
var ThresholdValueMode;
(function (ThresholdValueMode) {
    ThresholdValueMode[ThresholdValueMode["sum"] = 0] = "sum";
    ThresholdValueMode[ThresholdValueMode["avg"] = 1] = "avg";
    ThresholdValueMode[ThresholdValueMode["red"] = 2] = "red";
    ThresholdValueMode[ThresholdValueMode["green"] = 3] = "green";
    ThresholdValueMode[ThresholdValueMode["blue"] = 4] = "blue";
    ThresholdValueMode[ThresholdValueMode["max"] = 5] = "max";
    ThresholdValueMode[ThresholdValueMode["min"] = 6] = "min";
})(ThresholdValueMode = exports.ThresholdValueMode || (exports.ThresholdValueMode = {}));

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494054, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.ImagebTool = void 0;
class ImagebTool {
    static invertBitmap(canvas) {
        const ctx = canvas.getContext('2d');
        const pixels = ctx.getImageData(0, 0, canvas.width, canvas.height);
        const pixeldata = pixels.data;
        for (let i = 0, len = pixeldata.length; i < len; i += 4) {
            pixels.data[i] = 255 - pixels.data[i];
            pixels.data[i + 1] = 255 - pixels.data[i + 1];
            pixels.data[i + 2] = 255 - pixels.data[i + 2];
        }
        ctx.putImageData(pixels, 0, 0);
        return canvas;
    }
    static convertGreyImg(canvas) {
        const ctx = canvas.getContext('2d');
        const pixels = ctx.getImageData(0, 0, canvas.width, canvas.height);
        const pixeldata = pixels.data;
        for (let i = 0, len = pixeldata.length; i < len; i += 4) {
            const gray = pixels.data[i] * 0.3 + pixels.data[i + 1] * 0.59 + pixels.data[i + 2] * 0.11;
            pixels.data[i] = gray;
            pixels.data[i + 1] = gray;
            pixels.data[i + 2] = gray;
        }
        ctx.putImageData(pixels, 0, 0);
        return canvas;
    }
    static zeroAndOne(canvas) {
        const ctx = canvas.getContext('2d');
        const pixels = ctx.getImageData(0, 0, canvas.width, canvas.height);
        const index = 255 / 2; //阈值
        for (let i = 0; i < pixels.data.length; i += 4) {
            const R = pixels.data[i]; //R(0-255)
            const G = pixels.data[i + 1]; //G(0-255)
            const B = pixels.data[i + 2]; //B(0-255)
            const Alpha = pixels.data[i + 3]; //Alpha(0-255)
            const sum = (R + G + B) / 3;
            if (sum > index) {
                pixels.data[i] = 255;
                pixels.data[i + 1] = 255;
                pixels.data[i + 2] = 255;
                pixels.data[i + 3] = Alpha;
            }
            else {
                pixels.data[i] = 0;
                pixels.data[i + 1] = 0;
                pixels.data[i + 2] = 0;
                pixels.data[i + 3] = Alpha;
            }
        }
        ctx.putImageData(pixels, 0, 0);
        return canvas;
    }
}
exports.ImagebTool = ImagebTool;

}, function(modId) { var map = {}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494055, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.ReverseColorImage = void 0;
const process_1 = require("../process");
const types_1 = require("../../types");
const tools_1 = require("../../tools");
class ReverseColorImage extends process_1.ImagebProcesser {
    constructor(options) {
        super();
        this._processer = options === null || options === void 0 ? void 0 : options._processer;
    }
    process(input) {
        let result = tools_1.ImagebTool.invertBitmap(input);
        if (this._processer == null) {
            return new types_1.ProcessedResult({
                origin: input,
                result: new types_1.ProcessedImage({ data: result, width: result.width, height: result.height })
            });
        }
        return this._processer.process(result);
    }
}
exports.ReverseColorImage = ReverseColorImage;

}, function(modId) { var map = {"../process":1715917494051,"../../types":1715917494053,"../../tools":1715917494054}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494056, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.ThresholdImage = void 0;
const threshold_1 = require("../basic/threshold");
class ThresholdImage extends threshold_1.AbstractThreshold {
    constructor(options) {
        super(new threshold_1.PinedThresholdValue(options === null || options === void 0 ? void 0 : options.threshold));
    }
}
exports.ThresholdImage = ThresholdImage;

}, function(modId) { var map = {"../basic/threshold":1715917494057}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494057, function(require, module, exports) {

Object.defineProperty(exports, "__esModule", { value: true });
exports.PinedThresholdValue = exports.ThresholdValue = exports.AbstractThreshold = void 0;
const process_1 = require("../process");
const types_1 = require("../../types");
const tools_1 = require("../../tools");
class AbstractThreshold extends process_1.ImagebProcesser {
    constructor(threshold) {
        super();
        this.mode = types_1.ThresholdValueMode.avg;
        this.threshold = threshold !== null && threshold !== void 0 ? threshold : new PinedThresholdValue();
    }
    process(input) {
        let result = tools_1.ImagebTool.zeroAndOne(input);
        return new types_1.ProcessedResult({
            origin: input,
            result: new types_1.ProcessedImage({ data: result, width: result.width, height: result.height })
        });
    }
}
exports.AbstractThreshold = AbstractThreshold;
class ThresholdValue {
}
exports.ThresholdValue = ThresholdValue;
class PinedThresholdValue extends ThresholdValue {
    constructor(value) {
        super();
        this._value = value !== null && value !== void 0 ? value : 190;
    }
    threshold() {
        return this._value;
    }
}
exports.PinedThresholdValue = PinedThresholdValue;

}, function(modId) { var map = {"../process":1715917494051,"../../types":1715917494053,"../../tools":1715917494054}; return __REQUIRE__(map[modId], modId); })
__DEFINE__(1715917494058, function(require, module, exports) {

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
exports.Pbita = void 0;
const process_1 = require("../process");
const types_1 = require("../../types");
const pako = __importStar(require("pako"));
const gray_1 = require("../impls/gray");
const reverse_1 = require("../impls/reverse");
class Pbita extends process_1.ImagebProcesser {
    constructor(options) {
        super();
        this.threshold = options.threshold;
        this.command = options.command;
        this.compress = options.compress;
        this.reverse = options.reverse;
    }
    process(input) {
        const width = input.width;
        const height = input.height;
        const grayScaleImage = new gray_1.GrayscaleImage();
        const grayResult = grayScaleImage.process(input);
        if (grayResult.result == null) {
            return new types_1.ProcessedResult({
                origin: input,
                message: 'Failed to process gray scale: ' + grayResult.message
            });
        }
        let preprocessCanvas;
        if (this.reverse) {
            const reverseColorImage = new reverse_1.ReverseColorImage();
            const reverseResult = reverseColorImage.process(grayResult.result.data);
            if (reverseResult.result == null) {
                return new types_1.ProcessedResult({
                    origin: input,
                    message: 'Failed to process reverse: ' + reverseResult.message
                });
            }
            preprocessCanvas = reverseResult.result.data;
        }
        else {
            preprocessCanvas = grayResult.result.data;
        }
        let outputBytes = this._topbitimg(preprocessCanvas, width, height);
        if (outputBytes == null) {
            return new types_1.ProcessedResult({
                origin: input,
                message: 'Failed to process bitimg'
            });
        }
        if (this.compress) {
            outputBytes = pako.deflate(outputBytes, { windowBits: 10 });
        }
        return new types_1.ProcessedResult({
            origin: input,
            result: new types_1.ProcessedImage({
                data: preprocessCanvas,
                width: width,
                height: height,
                bytes: outputBytes
            })
        });
    }
    _topbitimg(canvas, width, height) {
        if (this.command == 'tspl' && !this.compress) {
            return this._topbitimgReverse(this._topbitimgRaw(canvas, width, height));
        }
        else {
            return this._topbitimgRaw(canvas, width, height);
        }
    }
    _topbitimgRaw(canvas, width, height) {
        var _a;
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
                const pixels = this.fastExtractPixel(imgData, x, currentHeight, 1, 1);
                const pixel = pixels[0];
                // const rgba = pixel.data;
                const red = pixel[0];
                const green = pixel[1];
                const blue = pixel[2];
                if ((red + green + blue) / 3 < ((_a = this.threshold) !== null && _a !== void 0 ? _a : 190)) {
                    bytes[index] = (bytes[index] | n);
                }
            }
            index = eWidth * (currentHeight + 1);
            currentHeight += 1;
        }
        return new Uint8Array(bytes);
    }
    _topbitimgReverse(originBytes) {
        if (originBytes == null) {
            return null;
        }
        const bytes = [];
        for (let i = 0; i < originBytes.length; i++) {
            bytes[i] = ~originBytes[i];
        }
        return new Uint8Array(bytes);
    }
    fastExtractPixel(imageData, x, y, w, h) {
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
exports.Pbita = Pbita;

}, function(modId) { var map = {"../process":1715917494051,"../../types":1715917494053,"../impls/gray":1715917494052,"../impls/reverse":1715917494055}; return __REQUIRE__(map[modId], modId); })
return __REQUIRE__(1715917494049);
})()
//miniprogram-npm-outsideDeps=["pako"]
//# sourceMappingURL=index.js.map