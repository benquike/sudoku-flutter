import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:sudoku/util/image_processing_service.dart';

ImageProcessingService getPIService() => WebImageProcessingService();

class WebImageProcessingService implements ImageProcessingService {
  @override
  img.Image copyMakeBorder(img.Image src, int top, int bottom, int left, int right, {int? value}) {
    final newWidth = src.width + left + right;
    final newHeight = src.height + top + bottom;
    final dst = img.Image(width: newWidth, height: newHeight);

    // Fill with border color
    dst.fill(value ?? 0);

    // Copy src image
    img.copyInto(dst, src, dstX: left, dstY: top);

    return dst;
  }

  @override
  Float32List blobFromImage(img.Image image, {double scalefactor = 1.0, required int width, required int height, bool swapRB = false}) {
    // This is a complex operation. For now, I'll throw an UnimplementedError.
    // A full implementation would require resizing, normalization, and channel reordering.
    throw UnimplementedError("blobFromImage is not yet implemented for web.");
  }
}
