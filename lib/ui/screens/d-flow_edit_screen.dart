import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/de1shotclasses.dart';
import 'package:despresso/ui/widgets/editable_text.dart';
import 'package:despresso/ui/widgets/profile_graph.dart';
import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;
import 'package:flutter_spinbox/material.dart';
import 'package:logging/logging.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import '../../model/services/ble/machine_service.dart';
import '../../service_locator.dart';

class DFlowEditScreen extends StatefulWidget {
  De1ShotProfile profile;

  DFlowEditScreen(this.profile, {Key? key}) : super(key: key);

  @override
  DFlowEditScreenState createState() {
    return DFlowEditScreenState(profile);
  }
}

class DFlowEditScreenState extends State<DFlowEditScreen> with SingleTickerProviderStateMixin {
  final log = Logger('DFlowEditScreenState');

  late ProfileService profileService;

  late EspressoMachineService machineService;

  final De1ShotProfile _profile;

  De1ShotFrameClass? preInfusion;
  // De1ShotFrameClass? forcedRise;
  De1ShotFrameClass? riseAndHold;
  De1ShotFrameClass? decline;

  De1ShotFrameClass? forcedRise;

  late TabController _tabController;

  List<MaterialColor> phaseColors = [Colors.blue, Colors.purple, Colors.green, Colors.brown];

  DFlowEditScreenState(this._profile);

  @override
  void initState() {
    super.initState();

    log.info('Init State ${_profile.shotHeader.title}');
  }

  @override
  void dispose() {
    super.dispose();

    // machineService.removeListener(profileListener);
    log.info('Disposed profile');
  }

  @override
  Widget build(BuildContext context) {
    // var items = profileService.profiles
    //     .map((p) => DropdownMenuItem(
    //           value: p,
    //           child: Text(p.shotHeader.title),
    //         ))
    //     .toList();

    return Scaffold(
      appBar: AppBar(
        title: IconEditableText(
          initialValue: _profile.shotHeader.title,
          onChanged: (value) {
            setState(() {
              _profile.shotHeader.title = value;
            });
          },
        ),
        //Text('Profile Edit: ${_profile.shotHeader.title}'),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Save'),
            onPressed: () {
              setState(() {
                profileService.save(_profile);
                Navigator.pop(context);
              });
            },
          ),
        ],
      ),
      body: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: IntrinsicHeight(
                child: ProfileGraphWidget(selectedProfile: _profile),
              ),
            ),
            // if (_profile.shotHeader.type != "advanced") SizedBox(height: 195, child: createTabBar()),
            if (_profile.shotHeader.type != "advanced")
              Expanded(
                child: IntrinsicHeight(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // ...handleChanges(preInfusion!),
                      // ...handleChanges(riseAndHold!),
                      // ...handleChanges(decline!),
                      // changeValue(
                      //     unit: "ml",
                      //     title: "Max. Volume",
                      //     min: 0,
                      //     max: 100,
                      //     De1ShotFrameClass(),
                      //     _profile.shotHeader.targetVolume, (value) {
                      //   var v = (value * 10).round() / 10;
                      //   setState(() => _profile.shotHeader.targetVolume = v);
                      // }),
                      // changeValue(
                      //     unit: "g",
                      //     title: "Max. Weight",
                      //     min: 0,
                      //     max: 100,
                      //     De1ShotFrameClass(),
                      //     _profile.shotHeader.targetWeight, (value) {
                      //   var v = (value * 10).round() / 10;
                      //   setState(() => _profile.shotHeader.targetWeight = v);
                      // }),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
