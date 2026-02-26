import '../models/home_response.dart';
import 'openrouter_service.dart';

class HomeResponseAiService {
  final OpenRouterService _openRouter = OpenRouterService();

  Future<HomeResponseData?> enhanceResponse({
    required HomeResponseData base,
    required String input,
    required List<String> signals,
    required String? memorySummary,
  }) async {
    if (base.escalationTier == EscalationTier.strong ||
        base.escalationTier == EscalationTier.crisis) {
      return null;
    }

    final payload = await _openRouter.generateHomeCard(
      input: input,
      signals: signals,
      memorySummary: memorySummary,
      responseShape: base.shape.name,
      escalationTier: base.escalationTier.name,
    );
    if (payload == null) {
      return null;
    }

    final whatMatters = _cleanLine(payload['what_matters']);
    final nextStep = _cleanLine(payload['next_step']);
    if (whatMatters == null || nextStep == null) {
      return null;
    }

    return HomeResponseData(
      whatMatters: whatMatters,
      nextStep: nextStep,
      shape: base.shape,
      escalationTier: base.escalationTier,
      actionChips: base.actionChips,
      statusLines: base.statusLines,
      signals: base.signals,
      rememberedSummary: base.rememberedSummary,
      memoryUsed: base.memoryUsed,
    );
  }

  String? _cleanLine(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
