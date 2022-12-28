import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:despresso/ui/screens/coffee_screen.dart';
import 'package:despresso/ui/screens/water_screen.dart';
import 'package:flutter/material.dart';
import 'theme.dart' as theme;

class HomePage extends StatefulWidget {
  HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool available = false;

  late CoffeeService coffeeSelection;
  late ProfileService profileService;

  @override
  void initState() {
    super.initState();
    coffeeSelection = getIt<CoffeeService>();
    coffeeSelection.addListener(() {
      setState(() {});
    });
    profileService = getIt<ProfileService>();
    profileService.addListener(() {
      setState(() {});
    });
  }

  Widget _buildButton(child, onpress) {
    var color = theme.Colors.backgroundColor;
    return Container(
        padding: EdgeInsets.all(10.0),
        child: TextButton(
          style: ButtonStyle(
            foregroundColor:
                MaterialStateProperty.all<Color>(theme.Colors.primaryColor),
            backgroundColor: MaterialStateProperty.all<Color>(color),
          ),
          onPressed: onpress,
          child: Container(
            height: 50,
            padding: EdgeInsets.all(10.0),
            child: child,
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    Widget coffee;
    var currentCoffee = coffeeSelection.currentCoffee;
    if (currentCoffee != null) {
      coffee = Row(children: [
        Spacer(
          flex: 2,
        ),
        Text(
          currentCoffee.roaster,
          style: theme.TextStyles.tabSecondary,
        ),
        Spacer(
          flex: 1,
        ),
        Text(
          currentCoffee.name,
          style: theme.TextStyles.tabSecondary,
        ),
        Spacer(
          flex: 2,
        ),
      ]);
    } else {
      coffee = Text(
        'No Coffee selected',
        style: theme.TextStyles.tabSecondary,
      );
    }
    Widget profile;
    var currentProfile = profileService.currentProfile;
    if (currentProfile != null) {
      profile = Text(
        currentProfile.name,
        style: theme.TextStyles.tabSecondary,
      );
    } else {
      profile = Text(
        'No Profile selected',
        style: theme.TextStyles.tabSecondary,
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: theme.Colors.screenBackground,
        ),
        child: Column(
          children: <Widget>[
            Spacer(
              flex: 2,
            ),
            Center(
                child: Image(
              image: AssetImage('assets/decent.png'),
              height: 120,
              color: theme.Colors.primaryColor,
            )),
            Spacer(
              flex: 3,
            ),
            Center(child: coffee),
            Center(child: profile),
            Spacer(
              flex: 3,
            ),
            Center(
              child: Wrap(
                runAlignment: WrapAlignment.spaceEvenly,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.center,
                children: [
                  _buildButton(
                    Text(
                      'Espresso',
                      style: theme.TextStyles.tabSecondary,
                    ),
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: ((context) => CoffeeScreen()),
                        )),
                  ),
                  _buildButton(
                    Text(
                      'Water / Steam / Flush',
                      style: theme.TextStyles.tabSecondary,
                    ),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: ((context) => WaterScreen()),
                      ),
                    ),
                  ),
                  _buildButton(
                      Text(
                        'Settings',
                        style: theme.TextStyles.tabSecondary,
                      ),
                      () => {}),
                ],
              ),
            ),
            Spacer(
              flex: 3,
            ),
          ],
        ),
      ),
    );
  }
}
