import 'package:aura/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  AppLocalizations get localizations => AppLocalizations.of(this)!;
}
