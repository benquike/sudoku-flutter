import 'package:sudoku/ml/ml_service.dart';
import 'package:tflite_web/tflite_web.dart';

MlService getMlService() => WebMlService();

class WebMlService implements MlService {
  late TFLiteModel _model;

  WebMlService() {
    TFLiteWeb.initialize();
  }

  @override
  Future<void> loadModel(String modelPath) async {
    _model = await TFLiteModel.fromUrl(modelPath);
  }

  @override
  Future<List> runInference(dynamic input) async {
    // Note: The input will need to be converted to a TFLiteTensor.
    // The output will also need to be decoded.
    // This is a placeholder implementation.
    final inputTensor = TFLiteTensor.fromList(input as List<List<List<List<double>>>>);
    final output = await _model.predict([inputTensor]);
    return output.map((tensor) => tensor.asList).toList();
  }
}
