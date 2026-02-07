import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:image/image.dart' as img;
import 'package:sudoku/util/image_processing_service.dart';
import 'package:sudoku/ml/ml_service.dart';
import 'package:sudoku/ml/predictor.dart';
import 'package:sudoku/ml/yolov8/yolov8_input.dart';
import 'package:sudoku/ml/yolov8/yolov8_output.dart';
import 'package:yaml/yaml.dart';

Logger log = Logger();

class YoloV8Detector extends Predictor<YoloV8Input, YoloV8Output> {
  final String modelPath;
  final String metadataPath;
  final double confThreshold;
  final double iouThreshold;
  final bool enableInt8Quantize;
  final (int, int) imgsz;
  final MlService mlService;
  late final YamlMap classes;

  YoloV8Detector._internal({
    required this.mlService,
    required this.classes,
    required this.modelPath,
    required this.metadataPath,
    required this.imgsz,
    required this.confThreshold,
    required this.iouThreshold,
    required this.enableInt8Quantize,
  });

  static Future<YoloV8Detector> load({
    required String modelPath,
    required String metadataPath,
    (int, int) imgsz = (640, 640),
    double confThreshold = 0.5,
    double iouThreshold = 0.45,
    @deprecated bool enableInt8Quantize = false,
  }) async {
    final mlService = MlService.instance;
    await mlService.loadModel(modelPath);

    String yamlContent = await rootBundle.loadString(metadataPath);
    var metadata = loadYaml(yamlContent);
    var classes = metadata['names'];

    return YoloV8Detector._internal(
      mlService: mlService,
      classes: classes,
      imgsz: imgsz,
      modelPath: modelPath,
      metadataPath: metadataPath,
      confThreshold: confThreshold,
      iouThreshold: iouThreshold,
      enableInt8Quantize: enableInt8Quantize,
    );
  }

  Float32List preprocess(YoloV8Input input) {
    var (int IMG_WIDTH, int IMG_HEIGHT) = this.imgsz;

    img.Image originImg = input.image;
    var oWidth = originImg.width;
    var oHeight = originImg.height;
    var length = oWidth > oHeight ? oWidth : oHeight;

    var dx = (length - oWidth) ~/ 2;
    var dy = (length - oHeight) ~/ 2;
    img.Image scaleImg = ImageProcessingService.instance.copyMakeBorder(
        originImg, dy, dy, dx, dx,
        value: 114);

    return ImageProcessingService.instance.blobFromImage(scaleImg,
        scalefactor: 1 / 255,
        width: IMG_WIDTH,
        height: IMG_HEIGHT,
        swapRB: true);
  }

  /// 2-d matrix transpose
  List _2dTranspose(List list) {
    if (list.isEmpty || list.first is! List) {
      throw new Exception("only support 2-D Tensor");
    }
    final int rows = list.length;
    final int cols = (list.first as List).length;

    // can not sure type , so try to get first value check runtime type
    var initV = list[0][0].runtimeType == double ? 0.0 : 0;
    List toReturn = List.generate(
        cols, (index) => List.generate(rows, (index) => initV));
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        toReturn[i][j] = list[j][i];
      }
    }
    return toReturn;
  }

  // postprocess(List output, {required int oHeight, required int oWidth}) {
  //   // TODO: This method needs to be reimplemented without opencv_dart.
  //   // This will require a pure Dart implementation of NMSBoxes.
  //   throw UnimplementedError("postprocess is not yet implemented without opencv_dart.");
  // }

  (double, int) _maxLoc(List list) {
    int loc = 0;
    var v = null;

    for (var (index, item) in list.indexed) {
      if (v == null) {
        v = item;
      }
      if (item > v) {
        v = item;
        loc = index;
      }
    }
    return (v, loc);
  }

  _predict(YoloV8Input input) async {
    // TODO: This method needs to be fully refactored to work with the new MlService.
    // The quantization logic and tensor metadata handling needs to be moved or adapted.

    DateTime preprocessBegin = DateTime.now();

    final _input = preprocess(input);
    // Quantization logic would go here...

    DateTime inferenceBegin = DateTime.now();

    var output = await mlService.runInference(_input);

    DateTime postprocessBegin = DateTime.now();
    // De-quantization and reshaping would go here...

    // List<YoloV8DetectionBox> boxes =
    //     postprocess(output, oHeight: input.image.height, oWidth: input.image.width);

    DateTime postprocessEnd = DateTime.now();

    var preprocessTimes = (inferenceBegin.microsecondsSinceEpoch -
            preprocessBegin.microsecondsSinceEpoch) /
        1000;
    var postprocessTimes = (postprocessEnd.microsecondsSinceEpoch -
            postprocessBegin.microsecondsSinceEpoch) /
        1000;
    var inferenceTimes = (postprocessBegin.microsecondsSinceEpoch -
            inferenceBegin.microsecondsSinceEpoch) /
        1000;

    log.d(
        "preprocessTimes:$preprocessTimes ms, postprocessTimes: $postprocessTimes ms, inferenceTimes: $inferenceTimes ms");

    return YoloV8Output(
        preprocessTimes: preprocessTimes,
        postprocessTimes: postprocessTimes,
        inferenceTimes: inferenceTimes,
        boxes: []); // returning empty list for now
  }

  @override
  Future<YoloV8Output> predict(YoloV8Input input) async {
    return await _predict(input);
  }
}
