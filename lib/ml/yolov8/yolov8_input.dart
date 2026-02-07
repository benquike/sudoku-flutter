import 'dart:io' as Io;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:sudoku/ml/predictor.dart';

/// YoloV8 Input
///
class YoloV8Input extends Input {
  final img.Image _image;

  YoloV8Input._internal(this._image);

  img.Image get image => this._image;

  static Future<YoloV8Input> readImg(String path) async {
    final bytes = await Io.File(path).readAsBytes();
    return YoloV8Input._internal(img.decodeImage(bytes)!);
  }

  static YoloV8Input readImgBytes(Uint8List bytes) {
    return YoloV8Input._internal(img.decodeImage(bytes)!);
  }
}
