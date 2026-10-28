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
  String get intensity => 'Intensité';

  @override
  String get warmth => 'Chaleur';

  @override
  String get lightLabel => 'Lumière ambiante';

  @override
  String get gestureHint =>
      'Glissez vers le haut ou le bas pour l\'intensité, vers la gauche ou la droite pour la chaleur. Touchez deux fois pour réinitialiser.';
}
