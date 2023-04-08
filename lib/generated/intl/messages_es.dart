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

  static String m0(sec) => "Vierta: ${sec} s";

  static String m1(sec) => "Total: ${sec} s";

  static String m2(sec) => "TTW: ${sec} s";

  static String m3(desc) => "Describa su experiencia con la toma de ${desc}";

  static String m4(flow) => "Caudal de vapor ${flow} ml/s";

  static String m5(temp) => "Detener a la temperatura ${temp} °C";

  static String m6(temp) => "Temperaturas de vapor ${temp} °C";

  static String m7(t) => "Temporizador ${t} s";

  static String m8(w) => "Peso ${w} g";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "beans": MessageLookupByLibrary.simpleMessage("Frijoles"),
        "blue": MessageLookupByLibrary.simpleMessage("Azul"),
        "disabled": MessageLookupByLibrary.simpleMessage("Desactivado"),
        "disconnected": MessageLookupByLibrary.simpleMessage("desconectado"),
        "edit": MessageLookupByLibrary.simpleMessage("EDITAR"),
        "enabled": MessageLookupByLibrary.simpleMessage("Activado"),
        "error": MessageLookupByLibrary.simpleMessage("error"),
        "exit": MessageLookupByLibrary.simpleMessage("Salida"),
        "flow": MessageLookupByLibrary.simpleMessage("Fluir"),
        "footerBattery": MessageLookupByLibrary.simpleMessage("Batería"),
        "footerConnect": MessageLookupByLibrary.simpleMessage("Conectar"),
        "footerGroup": MessageLookupByLibrary.simpleMessage("Grupo"),
        "footerProbe": MessageLookupByLibrary.simpleMessage("Investigacion"),
        "footerRefillWater":
            MessageLookupByLibrary.simpleMessage("recargar agua"),
        "footerScale": MessageLookupByLibrary.simpleMessage("Escala"),
        "footerTare": MessageLookupByLibrary.simpleMessage("  Tara"),
        "footerWater": MessageLookupByLibrary.simpleMessage("Agua"),
        "graphFlowMlsPressureBar": MessageLookupByLibrary.simpleMessage(
            "Caudal [ml/s] / Presión [bar]"),
        "graphTime": MessageLookupByLibrary.simpleMessage("Veces"),
        "green": MessageLookupByLibrary.simpleMessage("Verde"),
        "hide": MessageLookupByLibrary.simpleMessage("Esconder"),
        "mainMenuDespressoFeedback":
            MessageLookupByLibrary.simpleMessage("Comentarios de café"),
        "mainMenuEspressoDiary":
            MessageLookupByLibrary.simpleMessage("Diario de espresso"),
        "mainMenuFeedback": MessageLookupByLibrary.simpleMessage("Comentario"),
        "no": MessageLookupByLibrary.simpleMessage("No"),
        "off": MessageLookupByLibrary.simpleMessage("Apagado"),
        "ok": MessageLookupByLibrary.simpleMessage("De acuerdo"),
        "on": MessageLookupByLibrary.simpleMessage("En"),
        "orange": MessageLookupByLibrary.simpleMessage("Naranja"),
        "pressure": MessageLookupByLibrary.simpleMessage("Presión"),
        "privacy": MessageLookupByLibrary.simpleMessage("Privacidad"),
        "profile": MessageLookupByLibrary.simpleMessage("Perfil"),
        "profiles": MessageLookupByLibrary.simpleMessage("Perfiles"),
        "recipe": MessageLookupByLibrary.simpleMessage("Receta"),
        "reconnect": MessageLookupByLibrary.simpleMessage("reconectar"),
        "red": MessageLookupByLibrary.simpleMessage("Rojo"),
        "save": MessageLookupByLibrary.simpleMessage("Ahorrar"),
        "screenBeanSelectAcidity":
            MessageLookupByLibrary.simpleMessage("Acidez"),
        "screenBeanSelectAddressOfRoaster":
            MessageLookupByLibrary.simpleMessage("DIRECCIÓN"),
        "screenBeanSelectDaysAgo":
            MessageLookupByLibrary.simpleMessage("hace días"),
        "screenBeanSelectDescriptionOfBean":
            MessageLookupByLibrary.simpleMessage("Descripción"),
        "screenBeanSelectDescriptionOfRoaster":
            MessageLookupByLibrary.simpleMessage("Descripción"),
        "screenBeanSelectHomepageOfRoaster":
            MessageLookupByLibrary.simpleMessage("Página principal"),
        "screenBeanSelectIntensity":
            MessageLookupByLibrary.simpleMessage("Intensidad"),
        "screenBeanSelectNameOfBean":
            MessageLookupByLibrary.simpleMessage("Nombre"),
        "screenBeanSelectNameOfRoaster":
            MessageLookupByLibrary.simpleMessage("Nombre"),
        "screenBeanSelectRoastLevel":
            MessageLookupByLibrary.simpleMessage("Nivel de tueste"),
        "screenBeanSelectRoastingDate":
            MessageLookupByLibrary.simpleMessage("Fecha de tueste"),
        "screenBeanSelectSelectBeans":
            MessageLookupByLibrary.simpleMessage("Seleccione Frijoles"),
        "screenBeanSelectSelectRoaster":
            MessageLookupByLibrary.simpleMessage("Seleccionar tostador"),
        "screenBeanSelectTasting":
            MessageLookupByLibrary.simpleMessage("Saboreo"),
        "screenBeanSelectTitle":
            MessageLookupByLibrary.simpleMessage("Frijoles y Tostadores"),
        "screenBeanSelectTypeOfBeans":
            MessageLookupByLibrary.simpleMessage("Tipo de Frijoles"),
        "screenDiaryErrorUploadingShots":
            MessageLookupByLibrary.simpleMessage("Error al subir tomas"),
        "screenDiaryNoShotsToUploadSelected":
            MessageLookupByLibrary.simpleMessage(
                "No hay tomas para subir seleccionadas"),
        "screenDiaryNothingSelected":
            MessageLookupByLibrary.simpleMessage("Nada seleccionado"),
        "screenDiaryOverlaymode":
            MessageLookupByLibrary.simpleMessage("Modo de superposición:"),
        "screenDiarySuccessUploadingYourShots":
            MessageLookupByLibrary.simpleMessage("Éxito subiendo tus fotos"),
        "screenEspressoBean": MessageLookupByLibrary.simpleMessage("Café"),
        "screenEspressoDiary":
            MessageLookupByLibrary.simpleMessage("Diario de espresso"),
        "screenEspressoFlow": MessageLookupByLibrary.simpleMessage("Fluir"),
        "screenEspressoFlowMlsPressureBar":
            MessageLookupByLibrary.simpleMessage(
                "Caudal [ml/s] / Presión [bar]"),
        "screenEspressoPour": m0,
        "screenEspressoPressure":
            MessageLookupByLibrary.simpleMessage("Presión"),
        "screenEspressoProfile": MessageLookupByLibrary.simpleMessage("Perfil"),
        "screenEspressoRecipe": MessageLookupByLibrary.simpleMessage("Receta"),
        "screenEspressoRefillTheWaterTank":
            MessageLookupByLibrary.simpleMessage("Rellene el tanque de agua"),
        "screenEspressoTarget":
            MessageLookupByLibrary.simpleMessage("Objetivo"),
        "screenEspressoTemp":
            MessageLookupByLibrary.simpleMessage("Temperatura"),
        "screenEspressoTimer":
            MessageLookupByLibrary.simpleMessage("Temporizador"),
        "screenEspressoTimes": MessageLookupByLibrary.simpleMessage("Veces"),
        "screenEspressoTotal": m1,
        "screenEspressoTtw": m2,
        "screenEspressoWeight": MessageLookupByLibrary.simpleMessage("Peso"),
        "screenEspressoWeightG":
            MessageLookupByLibrary.simpleMessage("Peso (gramos]"),
        "screenRecipeAddRecipe":
            MessageLookupByLibrary.simpleMessage("Añadir receta"),
        "screenRecipeAdjustTempC":
            MessageLookupByLibrary.simpleMessage("Ajustar temperatura [°C]"),
        "screenRecipeCoffeeNotes":
            MessageLookupByLibrary.simpleMessage("notas de cafe"),
        "screenRecipeEditAdjustments":
            MessageLookupByLibrary.simpleMessage("Ajustes"),
        "screenRecipeEditDescription":
            MessageLookupByLibrary.simpleMessage("Descripción"),
        "screenRecipeEditDoseWeightin":
            MessageLookupByLibrary.simpleMessage("Peso de la dosis"),
        "screenRecipeEditDosingAndWeights":
            MessageLookupByLibrary.simpleMessage("Dosificación y pesos"),
        "screenRecipeEditGrinderModel":
            MessageLookupByLibrary.simpleMessage("Modelo"),
        "screenRecipeEditGrinderSettings":
            MessageLookupByLibrary.simpleMessage("Configuración del molinillo"),
        "screenRecipeEditMilkAndWater":
            MessageLookupByLibrary.simpleMessage("leche y agua"),
        "screenRecipeEditMilkWeight":
            MessageLookupByLibrary.simpleMessage("Peso de la leche"),
        "screenRecipeEditNameOfRecipe":
            MessageLookupByLibrary.simpleMessage("Nombre"),
        "screenRecipeEditRatio":
            MessageLookupByLibrary.simpleMessage("Relación"),
        "screenRecipeEditRatioTo": MessageLookupByLibrary.simpleMessage("a"),
        "screenRecipeEditTemperatureCorrection":
            MessageLookupByLibrary.simpleMessage("Corrección de temperatura"),
        "screenRecipeEditTitle":
            MessageLookupByLibrary.simpleMessage("Editar receta"),
        "screenRecipeEditUseSteam":
            MessageLookupByLibrary.simpleMessage("¿Usar vapor?"),
        "screenRecipeEditUseWater":
            MessageLookupByLibrary.simpleMessage("¿Usar agua?"),
        "screenRecipeEditWeightOut":
            MessageLookupByLibrary.simpleMessage("Peso fuera"),
        "screenRecipeGrindSettings":
            MessageLookupByLibrary.simpleMessage("Ajustes de molienda:"),
        "screenRecipeInitialTemp":
            MessageLookupByLibrary.simpleMessage("Temperatura inicial:"),
        "screenRecipeProfileDetails":
            MessageLookupByLibrary.simpleMessage("detalles del perfil"),
        "screenRecipeRatio": MessageLookupByLibrary.simpleMessage("Relación:"),
        "screenRecipeRecipeDetails":
            MessageLookupByLibrary.simpleMessage("Detalles de la receta"),
        "screenRecipeSelectedBean":
            MessageLookupByLibrary.simpleMessage("Frijol Seleccionado"),
        "screenRecipeSelectedProfile":
            MessageLookupByLibrary.simpleMessage("Perfil seleccionado"),
        "screenRecipeSetRatio":
            MessageLookupByLibrary.simpleMessage("Establecer proporción"),
        "screenRecipeStopOnWeightG":
            MessageLookupByLibrary.simpleMessage("Parada en peso [g]"),
        "screenRecipeWeightinBeansG":
            MessageLookupByLibrary.simpleMessage("Peso en frijoles [g]"),
        "screenRecipehotWater":
            MessageLookupByLibrary.simpleMessage("Agua caliente:"),
        "screenRecipesteamMilk":
            MessageLookupByLibrary.simpleMessage("Leche al vapor:"),
        "screenRoasterEditAddress":
            MessageLookupByLibrary.simpleMessage("DIRECCIÓN"),
        "screenRoasterEditDescription":
            MessageLookupByLibrary.simpleMessage("Descripción"),
        "screenRoasterEditHomepage":
            MessageLookupByLibrary.simpleMessage("Página principal"),
        "screenRoasterEditNameOfRoaster":
            MessageLookupByLibrary.simpleMessage("Nombre"),
        "screenRoasterEditTitle":
            MessageLookupByLibrary.simpleMessage("Editar tostador"),
        "screenSettingsApplicationSettings":
            MessageLookupByLibrary.simpleMessage(
                "Configuraciones de la aplicación"),
        "screenSettingsApplicationSettingsHardwareAndConnections":
            MessageLookupByLibrary.simpleMessage("Hardware y conexiones"),
        "screenSettingsApplicationSettingsScanForDevices":
            MessageLookupByLibrary.simpleMessage("Buscar dispositivos"),
        "screenSettingsApplicationSettingsScanStart":
            MessageLookupByLibrary.simpleMessage(
                "Busque DE1 y escalas (Lunar, Skale2, Eureka, Decent)"),
        "screenSettingsAutoTare":
            MessageLookupByLibrary.simpleMessage("Tara automática"),
        "screenSettingsBackup":
            MessageLookupByLibrary.simpleMessage("Respaldo"),
        "screenSettingsBackupAndMaintenance":
            MessageLookupByLibrary.simpleMessage(
                "Copia de seguridad y mantenimiento"),
        "screenSettingsBackupSettings": MessageLookupByLibrary.simpleMessage(
            "Configuración de copia de seguridad"),
        "screenSettingsBackuprestore": MessageLookupByLibrary.simpleMessage(
            "Copia de seguridad de restauracion"),
        "screenSettingsBackuprestoreDatabase":
            MessageLookupByLibrary.simpleMessage(
                "Copia de seguridad/restauración de la base de datos"),
        "screenSettingsBahaviour":
            MessageLookupByLibrary.simpleMessage("Comportamiento"),
        "screenSettingsBehaviour":
            MessageLookupByLibrary.simpleMessage("Comportamiento"),
        "screenSettingsBrightnessSleepAndScreensaver":
            MessageLookupByLibrary.simpleMessage(
                "Brillo, reposo y protector de pantalla"),
        "screenSettingsChangeHowTheAppIsChangingScreenBrightnessIfNot":
            MessageLookupByLibrary.simpleMessage(
                "Cambie la forma en que la aplicación cambia el brillo de la pantalla si no está en uso, encienda el de1 y apáguelo si no lo usa después de un tiempo."),
        "screenSettingsChangeHowTheAppIsHandlingTheDe1InCase":
            MessageLookupByLibrary.simpleMessage(
                "Cambie la forma en que la aplicación maneja el de1 en caso de despertarse y dormir."),
        "screenSettingsCheckYourRouterForIpAdressOfYourTabletOpen":
            MessageLookupByLibrary.simpleMessage(
                "Verifique su enrutador para la dirección IP de su tableta. Abra el navegador debajo"),
        "screenSettingsCloudAndNetwork":
            MessageLookupByLibrary.simpleMessage("Nube y red"),
        "screenSettingsCloudShotUpload":
            MessageLookupByLibrary.simpleMessage("Carga de tomas en la nube"),
        "screenSettingsCoffeePouring":
            MessageLookupByLibrary.simpleMessage("Verter café"),
        "screenSettingsCoffeeSection":
            MessageLookupByLibrary.simpleMessage("Café"),
        "screenSettingsDarkTheme":
            MessageLookupByLibrary.simpleMessage("tema oscuro"),
        "screenSettingsDeleteAllScreensaverFiles":
            MessageLookupByLibrary.simpleMessage(
                "Eliminar todos los archivos de salvapantallas"),
        "screenSettingsDoNotLetTabletGoToLockScreen0doNot":
            MessageLookupByLibrary.simpleMessage(
                "No permita que la tableta vaya a la pantalla de bloqueo (0 = no bloquear la pantalla, 240 = mantener siempre bloqueado) [min]"),
        "screenSettingsEnableMiniWebsiteWithPort8888":
            MessageLookupByLibrary.simpleMessage(
                "Habilitar mini sitio web con el puerto 8888"),
        "screenSettingsEnableMqtt":
            MessageLookupByLibrary.simpleMessage("Habilitar MQTT"),
        "screenSettingsEnglish": MessageLookupByLibrary.simpleMessage("Inglés"),
        "screenSettingsExitApp":
            MessageLookupByLibrary.simpleMessage("Salir de la aplicación"),
        "screenSettingsFailedRestoringBackup":
            MessageLookupByLibrary.simpleMessage(
                "Error al restaurar la copia de seguridad"),
        "screenSettingsFeedbackAndCrashReporting":
            MessageLookupByLibrary.simpleMessage(
                "Comentarios e informes de fallos"),
        "screenSettingsFlushTimerS": MessageLookupByLibrary.simpleMessage(
            "Temporizador de descarga [s]"),
        "screenSettingsGerman": MessageLookupByLibrary.simpleMessage("Alemán"),
        "screenSettingsGoBackToRecipeScreenIfTimeoutOccured":
            MessageLookupByLibrary.simpleMessage(
                "Volver a la pantalla Receta si se agotó el tiempo de espera"),
        "screenSettingsHandlingOfConnectionsToOtherExternalSystemsLikeMqttAnd":
            MessageLookupByLibrary.simpleMessage(
                "Manejo de conexiones a otros sistemas externos como MQTT y Visualizer."),
        "screenSettingsIfAShotIsStartingAutotareTheScale":
            MessageLookupByLibrary.simpleMessage(
                "Si está comenzando un disparo, tarar automáticamente la báscula"),
        "screenSettingsIfTheScaleIsConnectedItIsUsedToStop":
            MessageLookupByLibrary.simpleMessage(
                "Si la báscula está conectada sirve para parar el tiro si el perfil tiene un límite dado."),
        "screenSettingsIfYouHaveNoGhcInstalledYouWouldNeedThe":
            MessageLookupByLibrary.simpleMessage(
                "Si no tiene GHC instalado, necesitaría la pantalla de descarga"),
        "screenSettingsKeepTabletChargedBetween6090":
            MessageLookupByLibrary.simpleMessage(
                "Mantenga la tableta cargada entre 60-90%"),
        "screenSettingsKorean": MessageLookupByLibrary.simpleMessage("coreano"),
        "screenSettingsLanguage":
            MessageLookupByLibrary.simpleMessage("Idioma"),
        "screenSettingsLightTheme":
            MessageLookupByLibrary.simpleMessage("Tema ligero"),
        "screenSettingsLoadScreensaverFiles":
            MessageLookupByLibrary.simpleMessage(
                "Cargar archivos de salvapantallas"),
        "screenSettingsMessageQueueBroadcastMqttClient":
            MessageLookupByLibrary.simpleMessage(
                "Cliente de difusión de cola de mensajes (MQTT)"),
        "screenSettingsMilkSteamingThermometerSupport":
            MessageLookupByLibrary.simpleMessage(
                "Soporte termometro vaporizador de leche"),
        "screenSettingsMiniWebsite":
            MessageLookupByLibrary.simpleMessage("Minisitio web"),
        "screenSettingsMqttPassword":
            MessageLookupByLibrary.simpleMessage("Contraseña MQTT"),
        "screenSettingsMqttPort":
            MessageLookupByLibrary.simpleMessage("Puerto MQTT"),
        "screenSettingsMqttRootTopic":
            MessageLookupByLibrary.simpleMessage("Tema raíz de MQTT"),
        "screenSettingsMqttServer":
            MessageLookupByLibrary.simpleMessage("Servidor MQTT"),
        "screenSettingsMqttUser":
            MessageLookupByLibrary.simpleMessage("Usuario MQTT"),
        "screenSettingsPassword":
            MessageLookupByLibrary.simpleMessage("contraseña"),
        "screenSettingsPasswordCantBeSmallerThan7Letters":
            MessageLookupByLibrary.simpleMessage(
                "La contraseña no puede tener menos de 7 letras"),
        "screenSettingsPrivacySettings": MessageLookupByLibrary.simpleMessage(
            "La configuración de privacidad"),
        "screenSettingsReduceBrightnessToLevel":
            MessageLookupByLibrary.simpleMessage("Reducir el brillo al nivel"),
        "screenSettingsReduceScreenBrightnessAfter0offMin":
            MessageLookupByLibrary.simpleMessage(
                "Reducir el brillo de la pantalla después de (0=apagado) [min]"),
        "screenSettingsRestore":
            MessageLookupByLibrary.simpleMessage("Restaurar"),
        "screenSettingsRestoredBackup": MessageLookupByLibrary.simpleMessage(
            "Copia de seguridad restaurada"),
        "screenSettingsSavedBackup":
            MessageLookupByLibrary.simpleMessage("Copia de seguridad guardada"),
        "screenSettingsScaleSupport":
            MessageLookupByLibrary.simpleMessage("Soporte de escala"),
        "screenSettingsScreenAndBrightness":
            MessageLookupByLibrary.simpleMessage("Pantalla y Brillo"),
        "screenSettingsSecondFlushTimerS": MessageLookupByLibrary.simpleMessage(
            "Temporizador de segunda descarga [s]"),
        "screenSettingsSelectFiles":
            MessageLookupByLibrary.simpleMessage("Selecciona archivos"),
        "screenSettingsSendDe1ShotUpdates":
            MessageLookupByLibrary.simpleMessage(
                "Enviar actualizaciones de 1 toma"),
        "screenSettingsSendDe1StateUpdates":
            MessageLookupByLibrary.simpleMessage(
                "Enviar actualizaciones de estado de1"),
        "screenSettingsSendDe1WaterLevelUpdates":
            MessageLookupByLibrary.simpleMessage(
                "Enviar actualizaciones de nivel de agua de1"),
        "screenSettingsSendInformationsToSentryioIfTheAppCrashesOrYou":
            MessageLookupByLibrary.simpleMessage(
                "Envíe información a sentry.io si la aplicación falla o si usa la opción de comentarios. Consulte https://sentry.io/privacy/ para obtener una descripción detallada de la privacidad de datos."),
        "screenSettingsSendTabletBatteryLevelUpdates":
            MessageLookupByLibrary.simpleMessage(
                "Enviar actualizaciones del nivel de batería de la tableta"),
        "screenSettingsSendingTheStatusOfTheDe1":
            MessageLookupByLibrary.simpleMessage("Envío del estado del de1"),
        "screenSettingsSettingsAreRestoredPleaseCloseAppAndRestart":
            MessageLookupByLibrary.simpleMessage(
                "Se restauran los ajustes. Cierra la aplicación y reinicia."),
        "screenSettingsShotSettings":
            MessageLookupByLibrary.simpleMessage("Ajustes de tiro"),
        "screenSettingsShowFlush":
            MessageLookupByLibrary.simpleMessage("Mostrar al ras"),
        "screenSettingsSmartCharging":
            MessageLookupByLibrary.simpleMessage("Carga inteligente"),
        "screenSettingsSpanish":
            MessageLookupByLibrary.simpleMessage("Español"),
        "screenSettingsSpecialBluetoothDevices":
            MessageLookupByLibrary.simpleMessage(
                "Dispositivos Bluetooth especiales"),
        "screenSettingsStopBeforeWeightWasReachedS":
            MessageLookupByLibrary.simpleMessage(
                "Deténgase antes de alcanzar el peso [s]"),
        "screenSettingsStopOnWeightIfScaleDetected":
            MessageLookupByLibrary.simpleMessage(
                "Detener en peso si se detecta una báscula"),
        "screenSettingsSwitchDe1ToSleepModeIfItIsIdleFor":
            MessageLookupByLibrary.simpleMessage(
                "Cambie de1 al modo de suspensión si está inactivo durante algún tiempo [min]"),
        "screenSettingsSwitchOffSteamHeating":
            MessageLookupByLibrary.simpleMessage(
                "Apague la calefacción de vapor"),
        "screenSettingsSwitchOnScreensaverIfDe1ManuallySwitchedToSleep":
            MessageLookupByLibrary.simpleMessage(
                "Encienda el protector de pantalla si de1 cambió manualmente a suspensión"),
        "screenSettingsTabletDefault": MessageLookupByLibrary.simpleMessage(
            "Valor predeterminado de la tableta"),
        "screenSettingsTabletGroup":
            MessageLookupByLibrary.simpleMessage("Tableta"),
        "screenSettingsThemeSelection":
            MessageLookupByLibrary.simpleMessage("Selección de idioma y tema"),
        "screenSettingsThisCanLeadToAHigherLoadOnYourMqtt":
            MessageLookupByLibrary.simpleMessage(
                "Esto puede generar una mayor carga en su servidor MQTT ya que la frecuencia de los mensajes es de aproximadamente 10 Hz."),
        "screenSettingsToSaveEnergyTheSteamHeaterWillBeTurnedOff":
            MessageLookupByLibrary.simpleMessage(
                "Para ahorrar energía, el calentador de vapor se apagará y la pestaña de vapor se ocultará."),
        "screenSettingsUploadShotsToVisualizer":
            MessageLookupByLibrary.simpleMessage("Subir tomas al visualizador"),
        "screenSettingsUserNameCantBeSmallerThan4Letters":
            MessageLookupByLibrary.simpleMessage(
                "El nombre de usuario no puede tener menos de 4 letras"),
        "screenSettingsUserNameemail": MessageLookupByLibrary.simpleMessage(
            "Nombre de usuario/correo electrónico"),
        "screenSettingsWakeUpDe1IfAppIsLaunched":
            MessageLookupByLibrary.simpleMessage(
                "Activar de1 si se inicia la aplicación"),
        "screenSettingsWakeUpDe1IfScreenTappedIfScreenWasOff":
            MessageLookupByLibrary.simpleMessage(
                "Activar de1 si se toca la pantalla (si la pantalla estaba apagada)"),
        "screenSettingsYouChangedCriticalSettingsYouNeedToRestartTheApp":
            MessageLookupByLibrary.simpleMessage(
                "Cambió la configuración crítica. Debe reiniciar la aplicación para activar la configuración."),
        "screenShotEditBarrista":
            MessageLookupByLibrary.simpleMessage("barrista"),
        "screenShotEditDescribeYourExperience":
            MessageLookupByLibrary.simpleMessage("Describe tu experiencia"),
        "screenShotEditDoseWeightG":
            MessageLookupByLibrary.simpleMessage("Dosis peso [g]"),
        "screenShotEditDrinkWeightG":
            MessageLookupByLibrary.simpleMessage("Peso de la bebida [g]"),
        "screenShotEditDrinker":
            MessageLookupByLibrary.simpleMessage("Bebedor"),
        "screenShotEditEnjoyment":
            MessageLookupByLibrary.simpleMessage("Disfrute"),
        "screenShotEditExtractionYield":
            MessageLookupByLibrary.simpleMessage("Rendimiento de extracción"),
        "screenShotEditGrinder":
            MessageLookupByLibrary.simpleMessage("Amoladora"),
        "screenShotEditGrinderSettings":
            MessageLookupByLibrary.simpleMessage("Configuración del molinillo"),
        "screenShotEditOpenInVisualizercoffee":
            MessageLookupByLibrary.simpleMessage("Abrir en Visualizer.coffee"),
        "screenShotEditPouringTimeS":
            MessageLookupByLibrary.simpleMessage("Tiempo de vertido [s]"),
        "screenShotEditPouringWeightG":
            MessageLookupByLibrary.simpleMessage("Peso de colada [g]"),
        "screenShotEditSuccessUploadingYourShot":
            MessageLookupByLibrary.simpleMessage("Éxito al subir tu foto"),
        "screenShotEditTitle": m3,
        "screenShotEditTotalDissolvedSolidssTds":
            MessageLookupByLibrary.simpleMessage(
                "Sólidos Disueltos Totales (TDS)"),
        "screenSteamAmbient": MessageLookupByLibrary.simpleMessage("Ambiente"),
        "screenSteamFlowrate": m4,
        "screenSteamOffNormalPurgeAfterStop":
            MessageLookupByLibrary.simpleMessage(
                "Apagado (purga normal después de la parada)"),
        "screenSteamOnSlowPurgeOn1stStop": MessageLookupByLibrary.simpleMessage(
            "Encendido (purga lenta en la primera parada)"),
        "screenSteamReset": MessageLookupByLibrary.simpleMessage("Reiniciar"),
        "screenSteamStopAtTemperatur": m5,
        "screenSteamTempTip":
            MessageLookupByLibrary.simpleMessage("Punta de temperatura"),
        "screenSteamTemperaturs": m6,
        "screenSteamTimeS": MessageLookupByLibrary.simpleMessage("Veces"),
        "screenSteamTimerS": m7,
        "screenSteamTwotapMode":
            MessageLookupByLibrary.simpleMessage("Modo Steam de dos toques:"),
        "screenWaterWeightG": m8,
        "settings": MessageLookupByLibrary.simpleMessage("Ajustes"),
        "show": MessageLookupByLibrary.simpleMessage("Espectáculo"),
        "start": MessageLookupByLibrary.simpleMessage("Comenzar"),
        "stateDisconnected":
            MessageLookupByLibrary.simpleMessage("desconectado"),
        "stateIdleHeated": MessageLookupByLibrary.simpleMessage("calentado"),
        "statePour": MessageLookupByLibrary.simpleMessage("verter"),
        "state_Disconnected":
            MessageLookupByLibrary.simpleMessage("desconectado"),
        "steamScreenTempC":
            MessageLookupByLibrary.simpleMessage("temperatura [°C]"),
        "stop": MessageLookupByLibrary.simpleMessage("Detener"),
        "subStateHeatWaterHeater":
            MessageLookupByLibrary.simpleMessage("Calentando agua"),
        "subStateHeatWaterTank":
            MessageLookupByLibrary.simpleMessage("Tanque de calefacción"),
        "switchOn": MessageLookupByLibrary.simpleMessage("Encender"),
        "tabHomeEspresso": MessageLookupByLibrary.simpleMessage("Café exprés"),
        "tabHomeFlush": MessageLookupByLibrary.simpleMessage("Enjuagar"),
        "tabHomeRecipe": MessageLookupByLibrary.simpleMessage("Receta"),
        "tabHomeSteam": MessageLookupByLibrary.simpleMessage("Vapor"),
        "tabHomeWater": MessageLookupByLibrary.simpleMessage("Agua"),
        "temp": MessageLookupByLibrary.simpleMessage("Temperatura"),
        "validatorNotBeEmpty":
            MessageLookupByLibrary.simpleMessage("no debe estar vacío"),
        "wait": MessageLookupByLibrary.simpleMessage("Esperar"),
        "weight": MessageLookupByLibrary.simpleMessage("Peso")
      };
}
