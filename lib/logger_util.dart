import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:logging_appenders/logging_appenders.dart';
import 'package:path_provider/path_provider.dart';

Future<void> initLogger() async {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  // Logger.root.onRecord.listen((record) {
  //   print('APP#${record.level.name}: ${record.time}:${record.loggerName}# ${record.message}');
  // });
  Logger.root.clearListeners();
  PrintAppender(formatter: const ColorFormatter()).attachToLogger(Logger.root);

  Directory? dir;
  try {
    dir = await getDirectory();
    await dir?.create(recursive: true);
    // ignore: avoid_print
    print("Store log to ${dir?.path}");
  } catch (ex) {
    // ignore: avoid_print
    print("Error creating logfiles");
  }
  RotatingFileAppender(formatter: const DefaultLogRecordFormatter(), baseFilePath: "${dir!.path}/logs.txt")
      .attachToLogger(Logger.root);

  final log = Logger("APP");
  log.info("##############################");
  log.info("STARTING APPLICATION DESPRESSO");
  log.info("##############################");
}

Future<Directory?> getDirectory() async {
  Directory? dir;
  if (Platform.isAndroid) {
    dir = Directory('/storage/emulated/0/Download/despresso');
    try {
      await dir.create(recursive: true);
    } catch (e) {
      dir = await getExternalStorageDirectory();
    }
  } else {
    try {
      dir = await getExternalStorageDirectory();
    } on UnsupportedError catch (ex) {
      // ignore: avoid_print
      print("Not possible to store to external $ex");
      dir = await getApplicationDocumentsDirectory();
    }
  }

  return dir;
}

getLoggerBackupData() async {
  var store = await getDirectory();
  String file = "${store!.path}/logs.txt";
  var f = File(file);

  Uint8List data = f.readAsBytesSync();
  return data;
}
// class FileOutput extends LogOutput {
//   FileOutput(this.startSession) {}
//   bool startSession;
//   File? file;

//   @override
//   Future<void> init() async {
//     super.init();
//     if (startSession) {
//       FileOutput.startNewSession();
//     }
//     try {
//       Directory? dir;

//       try {
//         dir = await getExternalStorageDirectory();
//         if (Platform.isAndroid) {
//           dir = Directory('/storage/emulated/0/Download/despresso');
//         } else {
//           dir = await getExternalStorageDirectory();
//         }
//         await dir?.create(recursive: true);
//       } on UnsupportedError catch (ex) {
//         print("Not possible to store to external $ex");
//         dir = await getApplicationDocumentsDirectory();
//       }
//       if (dir != null) {
//         file = File("${dir.path}/logfile.txt");
//         print("loging: store to ${dir.path}");
//       }
//     } catch (e) {
//       print("Error $e");
//     }
//   }

//   @override
//   void output(OutputEvent event) async {
//     if (file != null) {
//       for (var line in event.lines) {
//         await file!.writeAsString("${line.toString()}\n", mode: FileMode.writeOnlyAppend);
//         print(line);
//       }
//     } else {
//       for (var line in event.lines) {
//         print(line);
//       }
//     }
//   }

//   static startNewSession() async {
//     try {
//       Directory? dir;

//       try {
//         dir = await getExternalStorageDirectory();
//         if (Platform.isAndroid) {
//           dir = Directory('/storage/emulated/0/Download/despresso');
//         } else
//           dir = await getExternalStorageDirectory();
//       } on UnsupportedError catch (ex) {
//         print("Not possible to store to external $ex");
//         dir = await getApplicationDocumentsDirectory();
//       }
//       if (dir != null) {
//         var file = File("${dir.path}/logfile_11.txt");
//         if (file.existsSync()) {
//           file.delete();
//           print("Logrotate delete ${file.path}");
//         }
//         for (int i = 10; i > -1; i--) {
//           var file = File("${dir.path}/logfile_$i.txt");
//           if (file.existsSync()) {
//             await file.rename("${dir.path}/logfile_${i + 1}.txt");
//             print("Logrotate ${file.path}");
//           }
//         }
//         file = File("${dir.path}/logfile.txt");
//         if (file.existsSync()) {
//           await file.rename("${dir.path}/logfile_0.txt");
//           print("Logrotate ${file.path}");
//         }
//       }
//     } catch (e) {
//       print("Error $e");
//     }
//   }
// }
