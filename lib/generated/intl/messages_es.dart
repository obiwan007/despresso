// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a es locale. All the
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
  String get localeName => 'es';

  static String m0(sec) => "Pour: ${sec} s";

  static String m1(sec) => "Total: ${sec} s";

  static String m2(sec) => "TTW: ${sec} s";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "no": MessageLookupByLibrary.simpleMessage("No"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "screenEspressoBean": MessageLookupByLibrary.simpleMessage("Coffee"),
        "screenEspressoDiary":
            MessageLookupByLibrary.simpleMessage("Espresso Diary"),
        "screenEspressoFlow": MessageLookupByLibrary.simpleMessage("Flow"),
        "screenEspressoFlowMlsPressureBar":
            MessageLookupByLibrary.simpleMessage(
                "Flow [ml/s] / Pressure [bar]"),
        "screenEspressoPour": m0,
        "screenEspressoPressure":
            MessageLookupByLibrary.simpleMessage("Pressure"),
        "screenEspressoProfile":
            MessageLookupByLibrary.simpleMessage("Profile"),
        "screenEspressoRecipe": MessageLookupByLibrary.simpleMessage("Recipe"),
        "screenEspressoRefillTheWaterTank":
            MessageLookupByLibrary.simpleMessage("Refill the water tank"),
        "screenEspressoTarget": MessageLookupByLibrary.simpleMessage("Target"),
        "screenEspressoTemp": MessageLookupByLibrary.simpleMessage("Temp"),
        "screenEspressoTimer": MessageLookupByLibrary.simpleMessage("Timer"),
        "screenEspressoTimes": MessageLookupByLibrary.simpleMessage("Time/s"),
        "screenEspressoTotal": m1,
        "screenEspressoTtw": m2,
        "screenEspressoWeight": MessageLookupByLibrary.simpleMessage("Weight"),
        "screenEspressoWeightG":
            MessageLookupByLibrary.simpleMessage("Weight [g]"),
        "screenRecipeAddRecipe":
            MessageLookupByLibrary.simpleMessage("Add recipe"),
        "screenRecipeAdjustTempC":
            MessageLookupByLibrary.simpleMessage("Adjust temp [°C]"),
        "screenRecipeCoffeeNotes":
            MessageLookupByLibrary.simpleMessage("Coffee notes"),
        "screenRecipeGrindSettings":
            MessageLookupByLibrary.simpleMessage("Grind Settings:"),
        "screenRecipeInitialTemp":
            MessageLookupByLibrary.simpleMessage("Initial temperature:"),
        "screenRecipeProfileDetails":
            MessageLookupByLibrary.simpleMessage("Profile Details"),
        "screenRecipeRatio": MessageLookupByLibrary.simpleMessage("Ratio:"),
        "screenRecipeRecipeDetails":
            MessageLookupByLibrary.simpleMessage("Recipe Details"),
        "screenRecipeSelectedBean":
            MessageLookupByLibrary.simpleMessage("Selected Bean"),
        "screenRecipeSelectedProfile":
            MessageLookupByLibrary.simpleMessage("Selected profile"),
        "screenRecipeSetRatio":
            MessageLookupByLibrary.simpleMessage("Set Ratio"),
        "screenRecipeStopOnWeightG":
            MessageLookupByLibrary.simpleMessage("Stop on Weight [g]"),
        "screenRecipeWeightinBeansG":
            MessageLookupByLibrary.simpleMessage("Weight-in beans [g]"),
        "screenRecipehotWater":
            MessageLookupByLibrary.simpleMessage("Hot water:"),
        "screenRecipesteamMilk":
            MessageLookupByLibrary.simpleMessage("Steam milk:"),
        "tabHomeEspresso": MessageLookupByLibrary.simpleMessage("Espresso"),
        "tabHomeFlush": MessageLookupByLibrary.simpleMessage("Flush"),
        "tabHomeSteam": MessageLookupByLibrary.simpleMessage("Steam"),
        "tabHomeWater": MessageLookupByLibrary.simpleMessage("Water")
      };
}
