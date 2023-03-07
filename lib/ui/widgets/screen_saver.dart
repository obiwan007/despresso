import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/animation/animation_controller.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/src/widgets/ticker_provider.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

class ScreenSaver extends StatefulWidget {
  const ScreenSaver({super.key});

  @override
  State<ScreenSaver> createState() => _ScreenSaverState();

  static Future<Directory> getDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final Directory saver = Directory('${directory.path}/screensaver/');
    if (!saver.existsSync()) {
      await saver.create(recursive: true);
    }
    return saver;
  }

  static Future<void> deleteAllFiles() async {
    var saver = await ScreenSaver.getDirectory();
    var entities = await saver.list().toList();
    for (var element in entities) {
      await element.delete();
    }
  }
}

class _ScreenSaverState extends State<ScreenSaver> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final log = Logger('ScreenSaver');

  List<String> _assetList = [];
  Image? _currentImage;

  Timer? _timer;

  @override
  initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _getListOfImages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var s = MediaQuery.of(context).size;

    var maxW = s.width - 250;
    var maxH = s.height - 170;

    var x = Random().nextDouble() * maxW;
    var y = Random().nextDouble() * maxH;

    Locale myLocale = Localizations.localeOf(context);
    var d = DateTime.now();
    var fmtT = DateFormat.Hm(myLocale.countryCode).format(d);
    var fmtD = DateFormat.MMMMEEEEd(myLocale.countryCode).format(d);
    return Stack(children: [
      Positioned.fill(
        left: 0,
        top: 0,
        child: _currentImage == null ? Text("aaa") : _currentImage!,
      ),
      Positioned(
          left: x,
          top: y,
          child: Opacity(
            opacity: 0.9,
            child: Column(
              children: [
                Text(
                  "${fmtT.toString()}",
                  style: TextStyle(fontSize: 100, color: Theme.of(context).colorScheme.primary),
                ),
                Text(
                  "${fmtD.toString()}",
                  style: TextStyle(fontSize: 30, color: Colors.white),
                ),
              ],
            ),
          )),
    ]);
  }

  startTimer() {
    _nextImage();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      _nextImage();
    });
  }

  _nextImage() {
    if (_assetList.isNotEmpty) {
      var i = Random().nextInt(_assetList.length);
      _currentImage = Image.file(File(_assetList[i]));
    }
    setState(() {});
  }

  _getListOfImages() async {
    var saver = await ScreenSaver.getDirectory();
    try {
      var entities = await saver.list().toList();
      _assetList = entities.map((e) => e.path).toList();

      for (var file in _assetList) {
        log.info("current screensaver $file");
      }
      startTimer();
    } catch (e) {
      log.severe("Error loading images for screensaver $e");
    }
  }
}
