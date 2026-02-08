import 'package:flutter/material.dart';

/// Global notifier for app locale. Set `value` to change language at runtime.
final ValueNotifier<Locale?> appLocale = ValueNotifier<Locale?>(null);
