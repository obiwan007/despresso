// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a de locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'de';

  static String m0(sec) => "Bezug: ${sec} s";

  static String m1(sec) => "Total: ${sec} s";

  static String m2(sec) => "TTW: ${sec} s";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "no": MessageLookupByLibrary.simpleMessage("Nein"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "screenEspressoBean": MessageLookupByLibrary.simpleMessage("Bohnen"),
        "screenEspressoDiary":
            MessageLookupByLibrary.simpleMessage("Espresso Logbuch"),
        "screenEspressoFlow": MessageLookupByLibrary.simpleMessage("Fluss"),
        "screenEspressoFlowMlsPressureBar":
            MessageLookupByLibrary.simpleMessage("Fluss [ml/s] / Druck [bar]"),
        "screenEspressoPour": m0,
        "screenEspressoPressure":
            MessageLookupByLibrary.simpleMessage("Pressure"),
        "screenEspressoProfile": MessageLookupByLibrary.simpleMessage("Profil"),
        "screenEspressoRecipe": MessageLookupByLibrary.simpleMessage("Rezept"),
        "screenEspressoRefillTheWaterTank":
            MessageLookupByLibrary.simpleMessage("Bitte Wassertank füllen"),
        "screenEspressoTarget": MessageLookupByLibrary.simpleMessage("Ziel"),
        "screenEspressoTemp": MessageLookupByLibrary.simpleMessage("Temp"),
        "screenEspressoTimer": MessageLookupByLibrary.simpleMessage("Timer"),
        "screenEspressoTimes": MessageLookupByLibrary.simpleMessage("Zeit/s"),
        "screenEspressoTotal": m1,
        "screenEspressoTtw": m2,
        "screenEspressoWeight": MessageLookupByLibrary.simpleMessage("Gewicht"),
        "screenEspressoWeightG":
            MessageLookupByLibrary.simpleMessage("Gewicht [g]"),
        "screenRecipeAddRecipe":
            MessageLookupByLibrary.simpleMessage("Rezept hinzufügen"),
        "screenRecipeAdjustTempC":
            MessageLookupByLibrary.simpleMessage("Temp Anpassen [°C]"),
        "screenRecipeCoffeeNotes":
            MessageLookupByLibrary.simpleMessage("Bohnen Infos"),
        "screenRecipeGrindSettings":
            MessageLookupByLibrary.simpleMessage("Mühlen Einst.:"),
        "screenRecipeInitialTemp":
            MessageLookupByLibrary.simpleMessage("Anfangs Temperatur:"),
        "screenRecipeProfileDetails":
            MessageLookupByLibrary.simpleMessage("Profil Infos"),
        "screenRecipeRatio":
            MessageLookupByLibrary.simpleMessage("Verhältniss:"),
        "screenRecipeRecipeDetails":
            MessageLookupByLibrary.simpleMessage("Rezept Infos"),
        "screenRecipeSelectedBean":
            MessageLookupByLibrary.simpleMessage("Gewählte Bohnen"),
        "screenRecipeSelectedProfile":
            MessageLookupByLibrary.simpleMessage("Gewähltes Profil"),
        "screenRecipeSetRatio":
            MessageLookupByLibrary.simpleMessage("Verhältniss einstellen"),
        "screenRecipeStopOnWeightG":
            MessageLookupByLibrary.simpleMessage("Stop bei Gewicht [g]"),
        "screenRecipeWeightinBeansG":
            MessageLookupByLibrary.simpleMessage("Einwaage Bohnen [g]"),
        "screenRecipehotWater":
            MessageLookupByLibrary.simpleMessage("Heißwasser:"),
        "screenRecipesteamMilk":
            MessageLookupByLibrary.simpleMessage("Milch schäumen:"),
        "tabHomeEspresso": MessageLookupByLibrary.simpleMessage("Espresso"),
        "tabHomeFlush": MessageLookupByLibrary.simpleMessage("Spülen"),
        "tabHomeRecipe": MessageLookupByLibrary.simpleMessage("Rezept"),
        "tabHomeSteam": MessageLookupByLibrary.simpleMessage("Dampf"),
        "tabHomeWater": MessageLookupByLibrary.simpleMessage("Wasser")
      };
}
