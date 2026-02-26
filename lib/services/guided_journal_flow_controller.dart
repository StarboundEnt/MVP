import '../models/journal_prompt_model.dart';

class GuidedJournalFlowController {
  final List<JournalPrompt> prompts;
  final Map<String, JournalPromptResponse> responses = {};

  int _currentIndex = 0;

  GuidedJournalFlowController({required this.prompts});

  int get currentIndex => _currentIndex;

  bool get isComplete => _currentIndex >= prompts.length;

  JournalPrompt get currentPrompt => prompts[_currentIndex];

  bool get isLastPrompt => _currentIndex == prompts.length - 1;

  void submitResponse(JournalPromptResponse response) {
    responses[response.promptId] = response;
    _advance();
  }

  void skipCurrent() {
    if (isComplete) return;
    final prompt = currentPrompt;
    responses[prompt.id] = JournalPromptResponse(
      promptId: prompt.id,
      skipped: true,
    );
    _advance();
  }

  void _advance() {
    if (_currentIndex < prompts.length) {
      _currentIndex += 1;
    }
  }
}
