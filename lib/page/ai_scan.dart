import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sudoku/l10n/sudoku_localizations.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';
import 'package:sudoku/ml/detector.dart';
import 'package:sudoku/ml/yolov8/yolov8_input.dart';
import 'package:sudoku/ml/yolov8/yolov8_output.dart';
import 'package:sudoku/page/ai_detection.dart';
import 'package:sudoku/util/crashlytics_util.dart';
import 'package:sudoku/util/image_util.dart';

final Logger log = Logger();

class AIScanPage extends StatefulWidget {
  const AIScanPage({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  AIScanPageState createState() => AIScanPageState();
}

class AIScanPageState extends State<AIScanPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final ImagePicker _picker = ImagePicker();

  bool _isPredicting = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.aiScanTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _pickImage,
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.

            return LayoutBuilder(
              builder: (context, constraints) {
                var _cameraWidget = SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: CameraPreview(_controller),
                );

                var _centerWidget = Center(
                  child: _isPredicting
                      ? CircularProgressIndicator()
                      : Text(
                          AppLocalizations.of(context)!
                              .aiSolverLensScanTipsText,
                          style:
                              TextStyle(color: Colors.white54, fontSize: 20)),
                );

                // 罩层 Overlay
                final (lrScale, tbScale) = _getLensOverlayScale(context);

                var _overlayWidget = Container(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                            color: Color.fromRGBO(0, 0, 0, 0.8),
                            width: tbScale * constraints.maxHeight),
                        bottom: BorderSide(
                            color: Color.fromRGBO(0, 0, 0, 0.8),
                            width: tbScale * constraints.maxHeight),
                        left: BorderSide(
                            color: Color.fromRGBO(0, 0, 0, 0.8),
                            width: lrScale * constraints.maxWidth),
                        right: BorderSide(
                            color: Color.fromRGBO(0, 0, 0, 0.8),
                            width: lrScale * constraints.maxWidth),
                      ),
                    ));

                return Stack(
                    children: [_cameraWidget, _overlayWidget, _centerWidget]);
              },
            );
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _predictPicture,
        child: const Icon(Icons.camera),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /// 从相册中选择图片并预测
  _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        return;
      }
      final imageBytes = await image.readAsBytes();
      ui.Image uiImage = await decodeImageFromList(imageBytes);
      await _processImage(uiImage, fromCamera: false);
    } catch (e, stacktrace) {
      log.e(e, stackTrace: stacktrace);
      CrashlyticsUtil.recordError(e, stacktrace);
    }
  }

  /// 预测照片中的数独
  /// Predict the number puzzle in the photo.
  _predictPicture() async {
    try {
      // Ensure that the camera is initialized.
      await _initializeControllerFuture;

      if (!context.mounted) {
        return;
      }

      // 数独检测 , 此处需要补充对图片进行剪切处理,降低图片尺寸也许可以加快推理时间 ??
      final picture = await _controller.takePicture();
      final pictureBytes = await picture.readAsBytes();
      ui.Image uiPicture = await decodeImageFromList(pictureBytes);
      await _processImage(uiPicture, fromCamera: true);
    } catch (e, stacktrace) {
      log.e(e, stackTrace: stacktrace);
      CrashlyticsUtil.recordError(e, stacktrace);
    }
  }

  /// process image and predict sudoku
  _processImage(ui.Image uiPicture, {required bool fromCamera}) async {
    try {
      if (!context.mounted) {
        return;
      }
      // show loading indicator
      setState(() {
        _isPredicting = true;
      });

      var sudokuPredictor = await DetectorFactory.getSudokuDetector();
      var digitsPredictor = await DetectorFactory.getDigitsDetector();

      ui.Image uiLensImg;

      if (fromCamera) {
        // 原相片大小 origin photo size
        final pictureHeight = uiPicture.height;
        final pictureWidth = uiPicture.width;

        // 取中间取景图像 , 排除掉遮罩部分
        // 计算上下/左右遮罩的比例
        final (lrScale, tbScale) = _getLensOverlayScale(context);

        // 取景器的x,y,w,h
        final double lensPicX = pictureWidth * lrScale;
        final double lensPicY = pictureHeight * tbScale;
        final double lensPicW = pictureWidth - lensPicX * 2;
        final double lensPicH = pictureHeight - lensPicY * 2;

        final lensImg = img.copyCrop(
          await ImageUtil.convertFlutterUiToImage(uiPicture),
          x: lensPicX.toInt(),
          y: lensPicY.toInt(),
          width: lensPicW.toInt(),
          height: lensPicH.toInt(),
        );
        uiLensImg = await ImageUtil.convertImageToFlutterUi(lensImg);
      } else {
        uiLensImg = uiPicture;
      }

      final lensImgBytes = img.encodeJpg(await ImageUtil.convertFlutterUiToImage(uiLensImg)).buffer.asUint8List();

      var input = YoloV8Input.readImgBytes(lensImgBytes);
      YoloV8Output sudokuOutput = sudokuPredictor.predict(input);

      final uiShowImg, showImgBytes, detectOutput;
      if (sudokuOutput.boxes.isNotEmpty) {
        final box = sudokuOutput.boxes[0];
        final x = box.x;
        final y = box.y;
        final w = box.w;
        final h = box.h;

        // crop sudoku part of image
        final cropSudokuImg = img.copyCrop(
          await ImageUtil.convertFlutterUiToImage(uiLensImg),
          x: x.toInt(),
          y: y.toInt(),
          width: w.toInt(),
          height: h.toInt(),
        );

        final uiCropSudokuImg =
            await ImageUtil.convertImageToFlutterUi(cropSudokuImg);
        final cropSudokuImgBytes =
            img.encodeJpg(cropSudokuImg).buffer.asUint8List();
        YoloV8Output digitsOutput = digitsPredictor
            .predict(YoloV8Input.readImgBytes(cropSudokuImgBytes));

        uiShowImg = uiCropSudokuImg;
        showImgBytes = cropSudokuImgBytes;
        detectOutput = digitsOutput;
      } else {
        uiShowImg = uiLensImg;
        showImgBytes = lensImgBytes;
        detectOutput = sudokuOutput;
      }

      // disable loading indicator
      if (context.mounted) {
        setState(() {
          _isPredicting = false;
        });
      }

      if (context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AIDetectPaintPage(
                image: uiShowImg, imageBytes: showImgBytes, output: detectOutput),
          ),
        );
      }
    } catch (e, stacktrace) {
      log.e(e, stackTrace: stacktrace);
      CrashlyticsUtil.recordError(e, stacktrace);
      if (context.mounted) {
        setState(() {
          _isPredicting = false;
        });
      }
    }
  }

  /// 遮罩占比
  ///
  /// return (leftRightScale,topBottomScale)
  (double, double) _getLensOverlayScale(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // 罩层 Overlay
    var _max = max(screenSize.width, screenSize.height);
    var _min = min(screenSize.width, screenSize.height);
    var _m = _max - _min;
    var _n = _min * 0.1;
    _m = (_m + _n) / 2;
    if (screenSize.width > screenSize.height) {
      // 横向
      var lrScale = _m / screenSize.width;
      var tbScale = _n / screenSize.height;
      return (lrScale, tbScale);
    } else {
      // 纵向
      var lrScale = _n / screenSize.width;
      var tbScale = _m / screenSize.height;
      return (lrScale, tbScale);
    }
  }
}
