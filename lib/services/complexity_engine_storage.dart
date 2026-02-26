import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/complexity_engine_models.dart';

class ComplexityEngineStorage {
  static const String _keyPersistedFactors = 'complexity_engine_factors';
  static const String _keyPersistedEvents = 'complexity_engine_events';
  static const String _keySuppressedCodes = 'complexity_engine_suppressed_codes';
  static const String _keyPendingFollowup = 'complexity_engine_pending_followup';
  static const String _keyUseSavedContext = 'complexity_engine_use_saved_context';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<List<Factor>> loadPersistedFactors() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString(_keyPersistedFactors);
    if (jsonString == null || jsonString.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! List) {
        return const [];
      }
      return decoded
          .whereType<Map>()
          .map((item) => Factor.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> savePersistedFactors(List<Factor> factors) async {
    final prefs = await _prefs;
    final encoded = jsonEncode(factors.map((factor) => factor.toJson()).toList());
    await prefs.setString(_keyPersistedFactors, encoded);
  }

  Future<void> addFactors(List<Factor> newFactors) async {
    if (newFactors.isEmpty) return;
    final existing = await loadPersistedFactors();
    final existingIds = existing.map((factor) => factor.id).toSet();
    final uniqueNew = newFactors
        .where((factor) => !existingIds.contains(factor.id))
        .toList();
    if (uniqueNew.isEmpty) return;
    final updated = [...existing, ...uniqueNew];
    await savePersistedFactors(updated);
  }

  Future<List<Event>> loadPersistedEvents() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString(_keyPersistedEvents);
    if (jsonString == null || jsonString.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! List) {
        return const [];
      }
      return decoded
          .whereType<Map>()
          .map((item) => _eventFromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> savePersistedEvents(List<Event> events) async {
    final prefs = await _prefs;
    final encoded = jsonEncode(events.map(_eventToJson).toList());
    await prefs.setString(_keyPersistedEvents, encoded);
  }

  Future<void> addEvent(Event event) async {
    if (event.saveMode == EventSaveMode.transient) return;
    final existing = await loadPersistedEvents();
    final index = existing.indexWhere((item) => item.id == event.id);
    if (index == -1) {
      final updated = [...existing, event];
      await savePersistedEvents(updated);
      return;
    }

    final current = existing[index];
    final shouldReplace =
        (current.rawText == null || current.rawText!.isEmpty) &&
            event.rawText != null &&
            event.rawText!.isNotEmpty;
    if (shouldReplace) {
      final updated = List<Event>.from(existing);
      updated[index] = event;
      await savePersistedEvents(updated);
    }
    return;
  }

  Future<Set<FactorCode>> getSuppressedCodes() async {
    final prefs = await _prefs;
    final list = prefs.getStringList(_keySuppressedCodes) ?? const [];
    return list
        .map((code) => FactorCodeX.fromCode(code))
        .whereType<FactorCode>()
        .toSet();
  }

  Future<void> suppressFactorCode(FactorCode code) async {
    final prefs = await _prefs;
    final existing = prefs.getStringList(_keySuppressedCodes) ?? const [];
    if (existing.contains(code.code)) return;
    final updated = [...existing, code.code];
    await prefs.setStringList(_keySuppressedCodes, updated);
  }

  Future<void> unsuppressFactorCode(FactorCode code) async {
    final prefs = await _prefs;
    final existing = prefs.getStringList(_keySuppressedCodes) ?? const [];
    final updated = existing.where((item) => item != code.code).toList();
    await prefs.setStringList(_keySuppressedCodes, updated);
  }

  Future<bool> getUseSavedContext() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyUseSavedContext) ?? true;
  }

  Future<void> setUseSavedContext(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyUseSavedContext, enabled);
  }

  Future<PendingFollowUp?> getPendingFollowUp() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString(_keyPendingFollowup);
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map) return null;
      return PendingFollowUp.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> setPendingFollowUp(PendingFollowUp followUp) async {
    final prefs = await _prefs;
    await prefs.setString(_keyPendingFollowup, jsonEncode(followUp.toJson()));
  }

  Future<void> clearPendingFollowUp() async {
    final prefs = await _prefs;
    await prefs.remove(_keyPendingFollowup);
  }

  Event _eventFromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      createdAt: json['created_at'] as String,
      parentEventId: json['parent_event_id'] as String?,
      intent: EventIntentX.fromCode(json['intent'] as String),
      saveMode: EventSaveModeX.fromCode(json['save_mode'] as String),
      rawText: json['raw_text'] as String?,
    );
  }

  Map<String, dynamic> _eventToJson(Event event) => {
        'id': event.id,
        'created_at': event.createdAt,
        'parent_event_id': event.parentEventId,
        'intent': event.intent.code,
        'save_mode': event.saveMode.code,
        'raw_text': event.rawText,
      };
}
