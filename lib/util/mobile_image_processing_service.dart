import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:sudoku/util/image_processing_service.dart';

ImageProcessingService getPIService() => MobileImageProcessingService();

class MobileImageProcessingService implements ImageProcessingService {
  @override
  img.Image copyMakeBorder(img.Image src, int top, int bottom, int left, int right, {int? value}) {
    final srcMat = _imageToMat(src);
    final dstMat = cv.copyMakeBorder(srcMat, top, bottom, left, right, cv.BORDER_CONSTANT, value: cv.Scalar.all((value ?? 0).toDouble()));
    return _matToImage(dstMat);
  }

  @override
  Float32List blobFromImage(img.Image image, {double scalefactor = 1.0, required int width, required int height, bool swapRB = false}) {
    final mat = _imageToMat(image);
    final blob = cv.blobFromImage(mat, scalefactor: scalefactor, size: (width, height), swapRB: swapRB, ddepth: cv.MatType.CV_32F);
    return Float32List.view(blob.data.buffer);
  }

  cv.Mat _imageToMat(img.Image image) {
    final pngBytes = img.encodePng(image);
    return cv.imdecode(pngBytes, cv.IMREAD_UNCHANGED);
  }

  img.Image _matToImage(cv.Mat mat) {
    final result = cv.imencode(".png", mat);
    return img.decodePng(result.$2)!;
  }
}
