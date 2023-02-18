import 'package:flutter/material.dart';

class ShotGraph extends StatefulWidget {
  int id;
  ShotGraph({Key? key, required this.id}) : super(key: key);

  @override
  _ShotGraphState createState() => _ShotGraphState(id);
}

class _ShotGraphState extends State<ShotGraph> {
  int id;
  _ShotGraphState(this.id) {}

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Text(id.toString()),
          Placeholder(color: Colors.red),
        ],
      ),
    );
  }
}
