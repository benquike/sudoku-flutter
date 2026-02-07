import 'stub_ml_service.dart'
    if (dart.library.io) 'mobile_ml_service.dart'
    if (dart.library.html) 'web_ml_service.dart';

abstract class MlService {
  Future<void> loadModel(String modelPath);

  Future<dynamic> runInference(dynamic input);

  static MlService get instance => getMlService();
}
