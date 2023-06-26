import 'package:flutter/material.dart';

class HeightWidget extends StatelessWidget {
  final double height;
  const HeightWidget({super.key, this.height = 10});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height);
  }
}
