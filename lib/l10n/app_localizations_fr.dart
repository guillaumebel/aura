// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Aura';

  @override
  String get chooseBackgroundColor => 'Choisir la couleur d\'arrière-plan';

  @override
  String get failedToSetBrightness =>
      'Échec de la configuration de la luminosité';

  @override
  String get chooseMode => 'Choisir le mode';

  @override
  String get auraMode => 'Aura';

  @override
  String get lavaLampMode => 'Lava lamp';
}
