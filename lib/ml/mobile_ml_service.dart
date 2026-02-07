import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:sudoku/ml/ml_service.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

MlService getMlService() => MobileMlService();

Logger log = Logger();

class MobileMlService implements MlService {
  late Interpreter _interpreter;

  @override
  Future<void> loadModel(String modelPath) async {
    _interpreter = await _buildInterpreterFromAsset(modelPath);
  }

  @override
  Future<List<dynamic>> runInference(dynamic input) async {
    // input is assumed to be Uint8List
    final inputTensor = _interpreter.getInputTensor(0);
    inputTensor.data = input as Uint8List;

    _interpreter.invoke();

    final outputTensor = _interpreter.getOutputTensor(0);
    return [outputTensor.data];
  }

  static Future<Interpreter> _buildInterpreterFromAsset(String modelPath) async {
    var interpreter;
    final delegates = <Delegate>[];
    if (Platform.isAndroid) {
      delegates.add(GpuDelegateV2());
      delegates.add(XNNPackDelegate());
    } else {
      delegates.add(GpuDelegate());
    }

    for (final gpuDelegate in delegates) {
      final options = InterpreterOptions()..addDelegate(gpuDelegate);
      try {
        log.i("use gpu delegate: $gpuDelegate");
        interpreter = await Interpreter.fromAsset(modelPath, options: options);
        break;
      } catch (_) {
        log.w("use gpu delegate: $gpuDelegate failure");
      }
    }

    interpreter ??= await Interpreter.fromAsset(modelPath);

    return interpreter;
  }
}
