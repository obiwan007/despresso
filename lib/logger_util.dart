import 'dart:io';

import 'package:logging/logging.dart';
import 'package:logging_appenders/logging_appenders.dart';
import 'package:path_provider/path_provider.dart';

Future<void> initLogger() async {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  // Logger.root.onRecord.listen((record) {
  //   print('APP#${record.level.name}: ${record.time}:${record.loggerName}# ${record.message}');
  // });
  // PrintAppender.setupLogging();
  PrintAppender(formatter: const ColorFormatter()).attachToLogger(Logger.root);

  Directory? dir;
  try {
    dir = await getExternalStorageDirectory();
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download/despresso');
    } else {
      dir = await getExternalStorageDirectory();
    }
    await dir?.create(recursive: true);
    print("Store log to ${dir?.path}");
  } catch (ex) {
    print("Error creating logfiles");
  }
  RotatingFileAppender(formatter: const DefaultLogRecordFormatter(), baseFilePath: "${dir!.path}/logs.txt")
      .attachToLogger(Logger.root);
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
