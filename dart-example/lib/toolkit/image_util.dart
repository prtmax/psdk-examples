
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageUtil {
  static img.Image copyResizeImage(CopyResizeArg arg) {
    return img.copyResize(
      arg.src,
      width: arg.width,
      height: arg.height,
      interpolation: arg.interpolation,
    );
  }

  /// rotate image
  static Future<Uint8List?> rotateImage(CopyRotateArg arg) async {
    img.Image? image = img.decodeImage(arg.src);
    if (image == null) {
      return null;
    }
    img.Image rotateImage = img.copyRotate(image, arg.angle);
    var rotatedBytes = Uint8List.fromList(img.encodePng(rotateImage));
    return rotatedBytes;
  }

  static Future<Uint8List?> dealPic(Uint8List image) async {

    Uint8List printImageData = image;
    img.Image croppedImage = img.decodeImage(printImageData)!;
    int imgWidth = croppedImage.width;
    int imgHeight = croppedImage.height;

    double paperWidthPixel = 200 * 12;
    double paperHeightPixel = 200 * 12;
    int finalW = imgWidth;
    int finalH = imgHeight;

    // The print image size > paper size
    if (imgWidth > paperWidthPixel || imgHeight > paperHeightPixel) {
      if (imgWidth > paperWidthPixel && imgHeight > paperHeightPixel) {
        double ratioW = imgWidth / paperWidthPixel;
        double ratioH = imgHeight / paperHeightPixel;
        if (ratioW > ratioH) {
          finalW = paperWidthPixel.round();
          finalH = imgHeight ~/ (imgWidth / finalW);
        } else {
          finalH = paperHeightPixel.round();
          finalW = imgWidth ~/ (imgHeight / finalH);
        }
      } else {
        if (imgWidth > paperWidthPixel) {
          finalW = paperWidthPixel.toInt();
          finalH = imgHeight ~/ (imgWidth / finalW);
        }
        if (imgHeight > paperHeightPixel) {
          finalH = paperHeightPixel.toInt();
          finalW = imgWidth ~/ (imgHeight / finalH);
        }
      }

      var output = await compute(
        copyResizeImage,
        CopyResizeArg(
          src: croppedImage,
          width: finalW - 6,
          height: finalH - 6,
          interpolation: img.Interpolation.average,
        ),
      );
      printImageData = Uint8List.fromList(img.encodePng(output));
    }
    var rotateImg = await compute(
      rotateImage,
      CopyRotateArg(
        src: printImageData,
        angle: 90,
      ),
    );
    return rotateImg;
  }
}

class CopyResizeArg {
  final img.Image src;
  final int? width;
  final int? height;
  final img.Interpolation interpolation;

  const CopyResizeArg({
    required this.src,
    this.width,
    this.height,
    this.interpolation = img.Interpolation.average,
  });
}
class CopyRotateArg {
  final Uint8List src;
  final num angle;

  const CopyRotateArg({
    required this.src,
    required this.angle,
  });
}
