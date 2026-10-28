// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Aura';

  @override
  String get intensity => 'Intensidad';

  @override
  String get warmth => 'Calidez';

  @override
  String get lightLabel => 'Luz ambiental';

  @override
  String get gestureHint =>
      'Desliza hacia arriba o abajo para la intensidad, a la izquierda o derecha para la calidez. Toca dos veces para restablecer.';
}
