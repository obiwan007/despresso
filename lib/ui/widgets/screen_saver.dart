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
    return _currentImage == null ? Text("Empty") : _currentImage!;
  }

  startTimer() {
    _nextImage();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      _nextImage();
    });
  }

  _nextImage() {
    var i = Random().nextInt(_assetList.length);
    _currentImage = Image.file(File(_assetList[i]));
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
      if (_assetList.length > 0) startTimer();
    } catch (e) {
      log.severe("Error loading images for screensaver $e");
    }
  }
}
