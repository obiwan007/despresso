import 'package:despresso/model/de1shotclasses.dart';
import 'package:despresso/ui/widgets/editable_text.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class SelectableSteps extends StatelessWidget {
  final log = Logger("SelectableStep");
  SelectableSteps(
      {super.key,
      required De1ShotProfile profile,
      required this.selected,
      required this.onSelected,
      this.onChanged,
      this.isEditable = true})
      : _profile = profile;

  final De1ShotProfile _profile;
  final Function(int) onSelected;
  final int selected;
  bool isEditable = false;
  Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.vertical,
      shrinkWrap: false,
      itemCount: _profile.shotFrames.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            bottomLeft: Radius.circular(32),
          ),
          child: ListTile(
            title: isEditable
                ? IconEditableText(
                    initialValue: _profile.shotFrames[index].name,
                    onChanged: (value) {
                      _profile.shotFrames[index].name = value;
                      if (onChanged != null) {
                        onChanged!(_profile.shotFrames[index].name);
                      }
                    })
                : Text(
                    _profile.shotFrames[index].name,
                  ),
            subtitle: getSubtitle(_profile.shotFrames[index]),
            selected: index == selected,
            onTap: () => onSelected(index),
          ),
        );
      },
    );
  }

  Widget getSubtitle(De1ShotFrameClass frame) {
    bool isMix = ((frame.flag & De1ShotFrameClass.TMixTemp) > 0);
    bool isGt = (frame.flag & De1ShotFrameClass.DC_GT) > 0;
    bool isFlow = (frame.flag & De1ShotFrameClass.DC_CompF) > 0;
    bool isCompared = (frame.flag & De1ShotFrameClass.DoCompare) > 0;
    String vol = "${frame.maxVol > 0 ? " or ${frame.maxVol} ml" : ""}";
    String limitFlow = "${frame.triggerVal > 0 ? "with a pressure limit of ${frame.triggerVal} bar" : ""}";
    String limitPressure = "${frame.triggerVal > 0 ? "with a flow limit of ${frame.triggerVal} ml/s" : ""}";
    log.info("RenderFrame Test: $frame");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Set ${isMix ? "water" : "coffee"} temperature to ${frame.temp.toStringAsFixed(0)} °C"),
        if (frame.pump != "pressure")
          Text("pour ${frame.transition} at rate of ${frame.setVal.toStringAsFixed(1)} ml/s $limitFlow"),
        if (frame.pump == "pressure")
          Text("Pressurize ${frame.transition} to ${frame.setVal.toStringAsFixed(1)} bar $limitPressure"),
        Text("For a maximum of ${frame.frameLen.toStringAsFixed(0)} seconds $vol"),
        if (isCompared)
          Text(
              "Move on if ${isFlow ? "flow" : "pressure"} is ${isGt ? "over" : "below"} ${frame.triggerVal.toStringAsFixed(1)} bar"),
      ],
    );
  }
}
