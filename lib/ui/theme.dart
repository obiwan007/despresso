import 'package:flutter/material.dart';

import 'package:flutter/material.dart' as material;

class ThemeColors {
  const ThemeColors();
  static const Color primaryColor = Color.fromARGB(255, 255, 255, 255); //Color(0xFFFFFFFF);
  static const Color secondaryColor = material.Colors.orange;
  static const Color goodColor = Color(0xFF32C2F0);
  static const Color badColor = Color(0xFFF28030);

  static const Map<String, Color> statesColors = {
    "flush": Color.fromARGB(100, 83, 43, 50),
    "pre_infuse": Color.fromARGB(100, 29, 81, 50),
    "pour": Color.fromARGB(100, 48, 138, 50),
    "heat_water_heater": Color.fromARGB(100, 198, 23, 40),
  };

  static const Color pressureColor = Color.fromARGB(255, 166, 250, 29); //Color(0xFFFFFFFF);
  static const Color tempColor = Color.fromARGB(255, 250, 45, 45);
  static const Color tempColor2 = Color.fromARGB(255, 255, 153, 0);
  static const Color flowColor = Color.fromARGB(255, 58, 157, 244);
  static const Color weightColor = Color.fromARGB(255, 131, 109, 105);

  static const Color backgroundColor = Color.fromARGB(255, 44, 44, 44); //material.Colors.white10; //0xFFFF4580
  static const Color graphBackground2 = Color.fromARGB(255, 44, 44, 44);
  static const Color graphBackground =
      material.Colors.white12; // HSLColor.fromColor(backgroundColor).withLightness(0.1).toColor();
  static const Color tabImageBorder = Color(0xFFFFFFFF); // 0xFFFFD2CF
  static final Color tabImageShadowColor = HSLColor.fromColor(backgroundColor).withLightness(0.7).toColor();
  static final Color tabShadowColor = HSLColor.fromColor(backgroundColor).withLightness(1).toColor();

  static const Color tabColor =
      material.Colors.red; // HSVColor.fromColor(backgroundColor).withValue(_value - .05).toColor();

  static final _value = HSVColor.fromColor(backgroundColor).value;
  static final _top = HSVColor.fromColor(backgroundColor).withValue(_value - .05).toColor();
  static final _bottom = HSVColor.fromColor(backgroundColor).withValue(_value - .1).toColor();

  static final screenBackground = LinearGradient(
    colors: [
      _top,
      backgroundColor,
      backgroundColor,
      _bottom,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: const [0.0, 0.15, 0.4, 1.0],
    tileMode: TileMode.clamp,
  );
}

class Dimens {
  const Dimens();

  static const imageWidth = 100.0;
  static const imageHeight = 100.0;

  static const buttonWidth = 60.0;
  static const buttonHeight = 60.0;
}

class TextStyles {
  const TextStyles();

  static const TextStyle h1 = TextStyle(
    color: ThemeColors.primaryColor,
    fontWeight: FontWeight.w300,
    fontSize: 18,
  );
  static const TextStyle h2 = TextStyle(
    color: ThemeColors.primaryColor,
    fontWeight: FontWeight.w300,
    fontSize: 16,
  );

  static const TextStyle tabPrimary = TextStyle(
    color: ThemeColors.secondaryColor,
    fontWeight: FontWeight.w300,
  );

  static const TextStyle tabSecondary = TextStyle(
    color: ThemeColors.secondaryColor,
    fontWeight: FontWeight.w100,
  );

  static const TextStyle tabTertiary = TextStyle(
    color: ThemeColors.primaryColor,
    fontWeight: FontWeight.w300,
  );

  static const TextStyle tabLabel = TextStyle(
    color: ThemeColors.primaryColor,
    fontWeight: FontWeight.w300,
  );
  static const TextStyle tabHeading = TextStyle(
    color: ThemeColors.primaryColor,
    // fontSize: 72.0,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle statusbuttonMain = TextStyle(
    color: ThemeColors.primaryColor,
    fontSize: 22.0,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle statusButtonSecondary = TextStyle(
    color: ThemeColors.primaryColor,
    fontWeight: FontWeight.w300,
  );
  static const TextStyle appBarTitle = TextStyle(
    color: ThemeColors.primaryColor,
    fontSize: 16.0,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle appBarTitleProfile = TextStyle(
    color: Color.fromARGB(255, 206, 206, 206),
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle headingFooter = TextStyle(
    color: ThemeColors.primaryColor,
    fontSize: 22.0,
    fontWeight: FontWeight.w300,
  );
  static const TextStyle headingFooterSmall = TextStyle(
    color: ThemeColors.primaryColor,
    fontSize: 16.0,
    fontWeight: FontWeight.w300,
  );
  static const TextStyle subHeadingFooter = TextStyle(
    color: ThemeColors.primaryColor,
    fontWeight: FontWeight.w100,
  );
}

class Helper {
  static Widget horizontalBorder() {
    return Container(
      color: ThemeColors.secondaryColor,
      width: 38.0,
      height: 1.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
    );
  }
}
