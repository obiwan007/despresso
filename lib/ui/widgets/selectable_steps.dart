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
      this.onCopied,
      this.onDeleted,
      this.onReordered,
      this.isEditable = true})
      : _profile = profile;

  final De1ShotProfile _profile;
  final Function(int) onSelected;
  final int selected;
  final bool isEditable;
  final Function(String)? onChanged;
  final Function(int)? onDeleted;
  final Function(int)? onCopied;
  final Function(int, int)? onReordered;

  String? getMoveOnSubtitle(De1ShotFrameClass frame) {
    bool isGt = (frame.flag & De1ShotFrameClass.dcGT) > 0;
    bool isFlow = (frame.flag & De1ShotFrameClass.dcCompF) > 0;
    bool isCompared = (frame.flag & De1ShotFrameClass.doCompare) > 0;

    if (!isCompared && frame.maxWeight == 0) {
      return null;
    }

    String subtitle = "Move on if ";

    if (isCompared) {
      subtitle +=
          "${isFlow ? "flow" : "pressure"} is ${isGt ? "over" : "below"} ${frame.triggerVal.toStringAsFixed(1)} ${isFlow ? "ml/s" : "bar"}";

      if (frame.maxWeight > 0.0) {
        subtitle += " or ";
      }
    }

    if (frame.maxWeight > 0.0) {
      subtitle += "weight is over ${frame.maxWeight}g";
    }

    return subtitle;
  }

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
          child: (isEditable)
              ? Dismissible(
                  key: UniqueKey(),
                  // confirmDismiss: (direction) {
                  //   return Future.delayed(
                  //     Duration(seconds: 1),
                  //     () {
                  //       return direction == DismissDirection.startToEnd;
                  //     },
                  //   );
                  // },
                  secondaryBackground: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    color: Colors.green,
                    alignment: Alignment.centerRight,
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text("Copy"),
                        Icon(
                          Icons.copy_all,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  background: Container(
                    color: Colors.red,
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    alignment: Alignment.centerLeft,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Text("Delete"),
                            Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  onDismissed: (direction) {
                    log.info(direction);
                    if (direction == DismissDirection.startToEnd &&
                        onDeleted != null) {
                      onDeleted!(index);
                    } else if (direction == DismissDirection.endToStart &&
                        onCopied != null) {
                      onCopied!(index);
                    }
                    // coffeeService.removeRecipe(data.id);
                    // setState(() {});
                  },
                  child: buildListTile(index),
                )
              : buildListTile(index),
        );
      },
    );
  }

  ListTile buildListTile(int index) {
    return ListTile(
      title: isEditable && index == selected
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
      trailing: isEditable && index == selected
          ? SizedBox(
              height: 100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (index > 0)
                    Expanded(
                      child: IconButton(
                        icon: const Icon(Icons.arrow_upward),
                        onPressed: () {
                          if (onReordered != null) {
                            onReordered!(index, -1);
                          }
                        },
                      ),
                    ),
                  if (index < _profile.shotFrames.length - 1)
                    Expanded(
                      child: IconButton(
                        icon: const Icon(Icons.arrow_downward),
                        onPressed: () {
                          if (onReordered != null) {
                            onReordered!(index, 1);
                          }
                        },
                      ),
                    ),
                ],
              ),
            )
          : null,
    );
  }

  Widget getSubtitle(De1ShotFrameClass frame) {
    De1ShotExtFrameClass extFrame = _profile.getExtFrame(frame);
    bool isMix = ((frame.flag & De1ShotFrameClass.tMixTemp) > 0);
    String vol = frame.maxVol > 0 ? " or ${frame.maxVol} ml" : "";
    String limitFlow = extFrame.limiterValue > 0
        ? "with a pressure limit of ${extFrame.limiterValue} bar"
        : "";
    String limitPressure = extFrame.limiterValue > 0
        ? "with a flow limit of ${extFrame.limiterValue} ml/s"
        : "";
    log.info("RenderFrame Test: $frame");

    var moveOnSubtitle = getMoveOnSubtitle(frame);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            "Set ${isMix ? "water" : "coffee"} temperature to ${frame.temp.toStringAsFixed(0)} °C"),
        if (frame.pump != "pressure")
          Text(
              "pour ${frame.transition} at rate of ${frame.setVal.toStringAsFixed(1)} ml/s $limitFlow"),
        if (frame.pump == "pressure")
          Text(
              "Pressurize ${frame.transition} to ${frame.setVal.toStringAsFixed(1)} bar $limitPressure"),
        Text(
            "For a maximum of ${frame.frameLen.toStringAsFixed(0)} seconds $vol"),
        if (moveOnSubtitle != null) Text(moveOnSubtitle),
      ],
    );
  }
}
