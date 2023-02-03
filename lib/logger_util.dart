import 'package:logger/logger.dart';

Logger getLogger() {
  return Logger(
    printer: SimplePrinter(
      colors: false,
      printTime: true,
    ),
  );
}
