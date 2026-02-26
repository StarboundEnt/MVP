import 'package:flutter/services.dart';

/// Lightweight runtime environment loader for bundled .env files.
class EnvService {
  EnvService._internal();

  static final EnvService instance = EnvService._internal();

  final Map<String, String> _values = {};
  bool _isLoaded = false;

  Future<void> load() async {
    if (_isLoaded) return;

    try {
      final contents = await rootBundle.loadString('.env');
      final entries = contents.split('\n');

      _values.clear();
      for (final rawLine in entries) {
        final line = rawLine.trim();
        if (line.isEmpty || line.startsWith('#')) {
          continue;
        }

        final separatorIndex = line.indexOf('=');
        if (separatorIndex == -1) {
          continue;
        }

        final key = line.substring(0, separatorIndex).trim();
        if (key.isEmpty) {
          continue;
        }

        var value = line.substring(separatorIndex + 1).trim();
        if (value.isEmpty) {
          continue;
        }

        if ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'"))) {
          value = value.substring(1, value.length - 1);
        }

        _values[key] = value;
      }
    } catch (_) {
      _values.clear();
    } finally {
      _isLoaded = true;
    }
  }

  String? maybe(String key) => _values[key];
}
