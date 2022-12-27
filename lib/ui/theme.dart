import 'package:flutter/material.dart';

class Colors {
  const Colors();

  static const Color primaryColor = Color(0xFFFFFFFF); //Color(0xFFFFFFFF);
  static const Color secondaryColor = Color(0xFFF2C230);
  static const Color goodColor = Color(0xFF32C2F0);
  static const Color badColor = Color(0xFFF28030);

  static const Color pressureColor =
      Color.fromARGB(255, 166, 250, 29); //Color(0xFFFFFFFF);
  static const Color tempColor = Color.fromARGB(255, 250, 45, 45);
  static const Color flowColor = Color.fromARGB(255, 255, 30, 199);

  static const Color backgroundColor = Color(0xFF184059); //0xFFFF4580
  static const Color tabImageBorder = Color(0xFFFFFFFF); // 0xFFFFD2CF
  static final Color tabImageShadowColor =
      HSLColor.fromColor(backgroundColor).withLightness(0.7).toColor();
  static final Color tabShadowColor =
      HSLColor.fromColor(backgroundColor).withLightness(1).toColor();

  static final Color tabColor =
      HSVColor.fromColor(backgroundColor).withValue(_value - .05).toColor();

  static final _value = HSVColor.fromColor(backgroundColor).value;
  static final _top =
      HSVColor.fromColor(backgroundColor).withValue(_value - .05).toColor();
  static final _bottom =
      HSVColor.fromColor(backgroundColor).withValue(_value - .1).toColor();

  static final screenBackground = LinearGradient(
    colors: [
      _top,
      backgroundColor,
      backgroundColor,
      _bottom,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.15, 0.4, 1.0],
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

  static const TextStyle tabPrimary = TextStyle(
      color: Colors.primaryColor,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w300,
      fontSize: 20.0);

  static const TextStyle tabSecondary = TextStyle(
      color: Colors.primaryColor,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w100,
      fontSize: 20.0);

  static const TextStyle tabTertiary = TextStyle(
      color: Colors.primaryColor,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w300,
      fontSize: 16.0);

  static const TextStyle tabLabel = TextStyle(
      color: Colors.primaryColor,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w300,
      fontSize: 16.0);
}

class Helper {
  static Widget horizontalBorder() {
    return Container(
      color: Colors.secondaryColor,
      width: 38.0,
      height: 1.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
    );
  }
}
