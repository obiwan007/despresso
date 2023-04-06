// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Hello World!`
  String get helloWorld {
    return Intl.message(
      'Hello World!',
      name: 'helloWorld',
      desc: 'The conventional newborn programmer greeting',
      args: [],
    );
  }

  /// `Recipe`
  String get tabHomeRecipe {
    return Intl.message(
      'Recipe',
      name: 'tabHomeRecipe',
      desc: '',
      args: [],
    );
  }

  /// `Espresso`
  String get tabHomeEspresso {
    return Intl.message(
      'Espresso',
      name: 'tabHomeEspresso',
      desc: '',
      args: [],
    );
  }

  /// `Steam`
  String get tabHomeSteam {
    return Intl.message(
      'Steam',
      name: 'tabHomeSteam',
      desc: '',
      args: [],
    );
  }

  /// `Water`
  String get tabHomeWater {
    return Intl.message(
      'Water',
      name: 'tabHomeWater',
      desc: '',
      args: [],
    );
  }

  /// `Flush`
  String get tabHomeFlush {
    return Intl.message(
      'Flush',
      name: 'tabHomeFlush',
      desc: '',
      args: [],
    );
  }

  /// `Recipe Details`
  String get screenRecipeRecipeDetails {
    return Intl.message(
      'Recipe Details',
      name: 'screenRecipeRecipeDetails',
      desc: '',
      args: [],
    );
  }

  /// `Hot water:`
  String get screenRecipehotWater {
    return Intl.message(
      'Hot water:',
      name: 'screenRecipehotWater',
      desc: '',
      args: [],
    );
  }

  /// `Steam milk:`
  String get screenRecipesteamMilk {
    return Intl.message(
      'Steam milk:',
      name: 'screenRecipesteamMilk',
      desc: '',
      args: [],
    );
  }

  /// `Profile Details`
  String get screenRecipeProfileDetails {
    return Intl.message(
      'Profile Details',
      name: 'screenRecipeProfileDetails',
      desc: '',
      args: [],
    );
  }

  /// `Coffee notes`
  String get screenRecipeCoffeeNotes {
    return Intl.message(
      'Coffee notes',
      name: 'screenRecipeCoffeeNotes',
      desc: '',
      args: [],
    );
  }

  /// `Selected profile`
  String get screenRecipeSelectedProfile {
    return Intl.message(
      'Selected profile',
      name: 'screenRecipeSelectedProfile',
      desc: '',
      args: [],
    );
  }

  /// `Initial temperature:`
  String get screenRecipeInitialTemp {
    return Intl.message(
      'Initial temperature:',
      name: 'screenRecipeInitialTemp',
      desc: '',
      args: [],
    );
  }

  /// `Selected Bean`
  String get screenRecipeSelectedBean {
    return Intl.message(
      'Selected Bean',
      name: 'screenRecipeSelectedBean',
      desc: '',
      args: [],
    );
  }

  /// `Grind Settings:`
  String get screenRecipeGrindSettings {
    return Intl.message(
      'Grind Settings:',
      name: 'screenRecipeGrindSettings',
      desc: '',
      args: [],
    );
  }

  /// `Ratio:`
  String get screenRecipeRatio {
    return Intl.message(
      'Ratio:',
      name: 'screenRecipeRatio',
      desc: '',
      args: [],
    );
  }

  /// `Weight-in beans [g]`
  String get screenRecipeWeightinBeansG {
    return Intl.message(
      'Weight-in beans [g]',
      name: 'screenRecipeWeightinBeansG',
      desc: '',
      args: [],
    );
  }

  /// `Stop on Weight [g]`
  String get screenRecipeStopOnWeightG {
    return Intl.message(
      'Stop on Weight [g]',
      name: 'screenRecipeStopOnWeightG',
      desc: '',
      args: [],
    );
  }

  /// `Adjust temp [°C]`
  String get screenRecipeAdjustTempC {
    return Intl.message(
      'Adjust temp [°C]',
      name: 'screenRecipeAdjustTempC',
      desc: '',
      args: [],
    );
  }

  /// `Add recipe`
  String get screenRecipeAddRecipe {
    return Intl.message(
      'Add recipe',
      name: 'screenRecipeAddRecipe',
      desc: '',
      args: [],
    );
  }

  /// `No`
  String get no {
    return Intl.message(
      'No',
      name: 'no',
      desc: '',
      args: [],
    );
  }

  /// `Set Ratio`
  String get screenRecipeSetRatio {
    return Intl.message(
      'Set Ratio',
      name: 'screenRecipeSetRatio',
      desc: '',
      args: [],
    );
  }

  /// `Ok`
  String get ok {
    return Intl.message(
      'Ok',
      name: 'ok',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'de'),
      Locale.fromSubtags(languageCode: 'es'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
