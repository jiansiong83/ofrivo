abstract final class AppCrashReporter {
  static Object? lastError;
  static StackTrace? lastStackTrace;

  static void record(Object error, [StackTrace? stackTrace]) {
    lastError = error;
    lastStackTrace = stackTrace;
  }

  static void clear() {
    lastError = null;
    lastStackTrace = null;
  }
}
