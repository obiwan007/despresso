import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

Logger getLogger() {
  return Logger(
    output: FileOutput(),
    printer: SimplePrinter(
      colors: false,
      printTime: true,
    ),
  );
}

class FileOutput extends LogOutput {
  FileOutput() {}

  File? file;

  @override
  Future<void> init() async {
    super.init();
    try {
      Directory? dir;

      try {
        dir = await getExternalStorageDirectory();
      } on UnsupportedError catch (ex) {
        print("Not possible to store to external $ex");
        dir = await getApplicationDocumentsDirectory();
      }
      if (dir != null) {
        file = File("${dir.path}/logfile.txt");
      }
    } catch (e) {
      print("Error $e");
    }
  }

  @override
  void output(OutputEvent event) async {
    if (file != null) {
      for (var line in event.lines) {
        await file!.writeAsString("${line.toString()}\n", mode: FileMode.writeOnlyAppend);
        print(line);
      }
    } else {
      for (var line in event.lines) {
        print(line);
      }
    }
  }
}
