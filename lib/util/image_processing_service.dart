import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'stub_image_processing_service.dart'
    if (dart.library.io) 'mobile_image_processing_service.dart'
    if (dart.library.html) 'web_image_processing_service.dart';

abstract class ImageProcessingService {
  img.Image copyMakeBorder(img.Image src, int top, int bottom, int left, int right, {int? value});

  Float32List blobFromImage(img.Image image, {double scalefactor, required int width, required int height, bool swapRB});

  static ImageProcessingService get instance => getPIService();
}
