import 'dart:math';

import '../models/complexity_engine_models.dart';
import '../complexity/question_framework.dart';
import 'complexity_engine_rules.dart';
import 'complexity_engine_storage.dart';
import 'openrouter_service.dart';

class ComplexityEngineService {
  static final ComplexityEngineService _instance =
      ComplexityEngineService._internal();
  factory ComplexityEngineService() => _instance;
  ComplexityEngineService._internal();

  final ComplexityEngineStorage _storage = ComplexityEngineStorage();
  final OpenRouterService _openRouter = OpenRouterService();
  bool _sessionUseProfile = true;

  bool get sessionUseProfile => _sessionUseProfile;

  void setSessionUseProfile(bool enabled) {
    _sessionUseProfile = enabled;
  }

  Future<void> clearSessionContext() async {
    _sessionUseProfile = true;
    await _storage.clearPendingFollowUp();
  }

  Future<bool> hasPendingFollowUp() async {
    final pending = await _storage.getPendingFollowUp();
    return pending != null;
  }

  Future<void> setUseSavedContext(bool enabled) async {
    await _storage.setUseSavedContext(enabled);
  }

  Future<void> suppressFactorCode(FactorCode code) async {
    await _storage.suppressFactorCode(code);
  }

  Future<void> unsuppressFactorCode(FactorCode code) async {
    await _storage.unsuppressFactorCode(code);
  }

  /// Generate an AI-powered follow-up question based on user input
  Future<FollowUpPlan?> generateAIFollowUp({
    required String inputText,
    required String? missingInfoHint,
  }) async {
    try {
      final question = await _openRouter.generateFollowupQuestion(
        inputText: inputText,
        hint: missingInfoHint,
      );

      if (question == null || question.trim().isEmpty) {
        return null;
      }

      // Return AI question with generic response choices
      return FollowUpPlan(
        questionText: question.trim(),
        choices: const [
          FollowUpChoice(label: 'Yes'),
          FollowUpChoice(label: 'No'),
          FollowUpChoice(label: 'Sort of'),
          FollowUpChoice(label: 'Tell me more'),
          FollowUpChoice(label: 'Skip'),
        ],
      );
    } catch (e) {
      // Fall back to null if AI fails
      return null;
    }
  }

  Future<ProcessSmartInputResult> processSmartInput({
    required String inputText,
    required EventIntent intent,
    required EventSaveMode saveMode,
    List<FactorWrite> factorWrites = const [],
    String? eventId,
    DateTime? createdAt,
  }) async {
    final pending = await _storage.getPendingFollowUp();
    final useSavedContext = await _storage.getUseSavedContext();
    final allowProfile = useSavedContext && _sessionUseProfile;
    final forcedIntent = pending != null ? EventIntent.followUp : intent;
    final previousQuestion = pending?.questionText;
    final followUpCount = pending?.followUpCount ?? 0;
    final symptomKeyFromPending = pending?.symptomKey;

    final event = Event(
      id: eventId ?? _generateId('evt'),
      createdAt: (createdAt ?? DateTime.now()).toIso8601String(),
      parentEventId: pending?.parentEventId,
      intent: forcedIntent,
      saveMode: saveMode,
      rawText: saveMode == EventSaveMode.saveJournal ? inputText : null,
    );

    final domainResult = classifyDomains(
      inputText,
      forcedIntent,
      previousQuestion: previousQuestion,
    );

    final extracted = extractFactors(
      inputText,
      domainResult,
      forcedIntent,
      event.id,
    );

    final suppressedCodes = await _storage.getSuppressedCodes();
    final mergedFactors =
        applyFactorWrites(extracted.factors, factorWrites, event.id);
    final filteredFactors = mergedFactors
        .where((factor) => !suppressedCodes.contains(factor.code))
        .toList();
    final filteredExtracted = filterMissingInfo(
      ExtractedPayload(
        factors: filteredFactors,
        missingInfo: extracted.missingInfo,
      ),
    );

    final shouldPersist = saveMode != EventSaveMode.transient &&
        (allowProfile || saveMode == EventSaveMode.saveJournal);
    if (shouldPersist) {
      await _storage.addEvent(event);
      await _storage.addFactors(filteredFactors);
    }

    final persistedFactors =
        allowProfile ? await _storage.loadPersistedFactors() : const [];
    final profile = buildComplexityProfile(
      [...persistedFactors, ...filteredFactors],
      suppressedCodes: suppressedCodes,
    );

    var snapshot = buildStateSnapshot(
      event,
      domainResult,
      filteredExtracted,
      profile,
    );

    final resolvedSymptomKey =
        symptomKeyFromPending ?? detectSymptomKey(inputText, filteredFactors);

    // Check if a follow-up is needed using rules
    final rulesFollowUpPlan = chooseNextFollowUp(
      inputText,
      filteredFactors,
      resolvedSymptomKey,
      followUpCount,
      snapshot.riskBand,
    );

    // If rules say we need a follow-up, try to generate an AI question instead
    FollowUpPlan? followUpPlan;
    if (rulesFollowUpPlan != null &&
        snapshot.nextActionKind == NextActionKind.answer &&
        event.intent != EventIntent.logOnly) {
      // Try AI-generated follow-up first
      final missingHint = filteredExtracted.missingInfo?.isNotEmpty == true
          ? filteredExtracted.missingInfo!.first.key
          : null;
      followUpPlan = await generateAIFollowUp(
        inputText: inputText,
        missingInfoHint: missingHint,
      );
      // Fall back to rule-based if AI fails
      followUpPlan ??= rulesFollowUpPlan;
    }

    if (followUpPlan != null &&
        snapshot.nextActionKind == NextActionKind.answer &&
        event.intent != EventIntent.logOnly) {
      snapshot = snapshot.copyWith(
        nextActionKind: NextActionKind.askFollowup,
        followupQuestion: followUpPlan.questionText,
        symptomKey: resolvedSymptomKey,
        followUpCount: followUpCount + 1,
      );
    } else {
      snapshot = snapshot.copyWith(
        symptomKey: resolvedSymptomKey,
        followUpCount: followUpCount,
      );
    }

    final routed = routeNextStep(snapshot);

    final whatImUsing = buildWhatImUsingModel(
      snapshot,
      useSavedContext: useSavedContext,
      sessionUseProfile: _sessionUseProfile,
    );

    final responseModel = buildResponseModel(
      inputText,
      snapshot,
      routed,
      whatImUsing,
      filteredFactors,
      followUpPlan: followUpPlan,
    );

    if (pending != null) {
      await _storage.clearPendingFollowUp();
    }

    if (snapshot.nextActionKind == NextActionKind.askFollowup &&
        followUpPlan != null &&
        snapshot.riskBand != RiskBand.urgent &&
        event.intent != EventIntent.logOnly) {
      await _storage.setPendingFollowUp(
        PendingFollowUp(
          id: _generateId('pfu'),
          parentEventId: event.id,
          questionText: followUpPlan.questionText,
          missingInfoKey: filteredExtracted.missingInfo?.isNotEmpty == true
              ? filteredExtracted.missingInfo!.first.key
              : null,
          createdAt: DateTime.now().toIso8601String(),
          followUpCount: snapshot.followUpCount,
          symptomKey: snapshot.symptomKey,
        ),
      );
    }

    return ProcessSmartInputResult(
      event: event,
      domainResult: domainResult,
      extracted: filteredExtracted,
      profile: profile,
      snapshot: snapshot,
      responseModel: responseModel,
    );
  }

  String _generateId(String prefix) {
    final random = Random().nextInt(999999);
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}_$random';
  }
}
