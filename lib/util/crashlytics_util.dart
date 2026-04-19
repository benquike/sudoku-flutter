import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:logger/logger.dart';
import 'package:sudoku/constant.dart';
import 'package:sudoku/config/app_config.dart';

Logger log = Logger();

class CrashlyticsUtil {
  static void recordError(dynamic error, dynamic stackTrace) {
    if (!AppConfig.forEnvironment().enableGoogleFirebase) {
      log.w("not enable google firebase crashlytics service");
      log.w(error, stackTrace: stackTrace);
      return;
    }
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
}
