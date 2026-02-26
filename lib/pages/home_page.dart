import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/home_response_card.dart';
import '../components/smart_input_widget.dart';
import '../design_system/design_system.dart';
import '../models/complexity_engine_models.dart';
import '../models/home_response.dart';
import '../models/habit_model.dart';
import '../models/journal_prompt_model.dart';
import '../models/service_model.dart';
import '../pages/ask_page.dart';
import '../providers/app_state.dart';
import '../services/complexity_engine_service.dart';
import '../services/guided_journal_service.dart';
import '../services/journaling_reminder_service.dart';
import '../services/openrouter_service.dart';
import '../services/home_response_service.dart';
import '../services/home_response_ai_service.dart';
import '../services/smart_input_service.dart';
import '../services/user_support_network_service.dart';
import '../widgets/guided_journal_flow.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onSupportPressed;
  final VoidCallback onActionVaultPressed;
  final VoidCallback onJournalPressed;
  final VoidCallback onInsightsPressed;
  final VoidCallback onSettingsPressed;

  const HomePage({
    Key? key,
    required this.onSupportPressed,
    required this.onActionVaultPressed,
    required this.onJournalPressed,
    required this.onInsightsPressed,
    required this.onSettingsPressed,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeResponseService _responseService = HomeResponseService();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final GlobalKey<AskPageState> _askPageKey = GlobalKey<AskPageState>();
  final UserSupportNetworkService _supportNetworkService =
      UserSupportNetworkService();
  final HomeResponseAiService _homeResponseAiService = HomeResponseAiService();
  final OpenRouterService _openRouter = OpenRouterService();
  final GuidedJournalService _guidedJournalService =
      const GuidedJournalService();
  final ComplexityEngineService _complexityEngine = ComplexityEngineService();
  final JournalingReminderService _journalingReminderService =
      JournalingReminderService();

  HomeResponseData? _response;
  SmartInputResult? _lastInputResult;
  bool _lastWasLogOnly = false;
  bool _useMemoryForRequest = true;
  bool _lastRequestUseMemory = true;
  int _responseNonce = 0;
  bool _showAskPanel = false;
  String? _supportConcernLabel;
  List<SupportService> _supportSuggestions = const [];
  String? _lastInputText;
  bool _showGuidedJournalFlow = false;
  String? _guidedJournalDraft;
  int _guidedJournalSessionId = 0;
  bool _isGuidedJournalLoading = false;
  List<JournalPrompt> _guidedJournalPrompts = const [];

  @override
  void initState() {
    super.initState();
    _supportNetworkService.initialize();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSmartInput(SmartInputResult result) async {
    _lastInputText = result.processedText.trim();
    _updateSupportSuggestions(result);

    if (_showGuidedJournalFlow) {
      setState(() {
        _showGuidedJournalFlow = false;
        _guidedJournalDraft = null;
        _isGuidedJournalLoading = false;
      });
    }

    if (result.intent == SmartRouteIntent.guidedJournal) {
      await _startGuidedJournalFlow(result.processedText);
      return;
    }

    if (result.intent == SmartRouteIntent.ask) {
      _submitAsk(
        result.processedText,
        responseModel: result.responseModel,
        engineEventId: result.engineEventId,
        engineCreatedAt: result.engineCreatedAt,
      );
      if (mounted) {
        setState(() {
          _response = null;
          _lastInputResult = result;
          _lastWasLogOnly = false;
          _lastRequestUseMemory = _useMemoryForRequest;
          _useMemoryForRequest = true;
        });
      }
      return;
    }

    if (result.intent == SmartRouteIntent.both) {
      _submitAsk(
        result.processedText,
        responseModel: result.responseModel,
        engineEventId: result.engineEventId,
        engineCreatedAt: result.engineCreatedAt,
      );
    }

    final appState = context.read<AppState>();
    final useMemory = _useMemoryForRequest;
    final memoryContext = _buildMemoryContext(appState, useMemory);
    final decision = _responseService.buildDecision(
      result,
      memoryContext: memoryContext,
      complexityLevel: appState.complexityProfile,
    );

    if (decision.logOnly) {
      if (mounted) {
        setState(() {
          _response = decision.response;
          _lastInputResult = result;
          _lastWasLogOnly = true;
          _lastRequestUseMemory = useMemory;
          _useMemoryForRequest = true;
        });
      }
      _responseNonce++;
      return;
    }

    if (decision.shouldSave) {
      await _saveJournalEntry(result, showToast: false);
    }

    if (mounted) {
      final int nonce = ++_responseNonce;
      setState(() {
        _response = decision.response;
        _lastInputResult = result;
        _lastWasLogOnly = false;
        _lastRequestUseMemory = useMemory;
        _useMemoryForRequest = true;
      });
      _maybeEnhanceResponse(
        result,
        decision.response,
        memoryContext,
        nonce,
      );
    }
  }

  Future<void> _startGuidedJournalFlow(String? draftText) async {
    _inputController.clear();
    _inputFocusNode.unfocus();

    final complexityLevel = context.read<AppState>().complexityProfile;

    setState(() {
      _guidedJournalDraft = draftText?.trim().isEmpty == true ? null : draftText;
      _showGuidedJournalFlow = true;
      _guidedJournalSessionId += 1;
      _isGuidedJournalLoading = true;
    });

    final prompts = await _guidedJournalService.buildV1PromptsForInput(
      _guidedJournalDraft,
      complexityLevel,
    );
    if (!mounted) return;
    setState(() {
      _guidedJournalPrompts = prompts;
      _isGuidedJournalLoading = false;
    });
  }

  Future<void> _handleGuidedJournalCompleted(
      GuidedJournalResult result) async {
    setState(() {
      _showGuidedJournalFlow = false;
      _guidedJournalDraft = null;
      _isGuidedJournalLoading = false;
    });

    if (result.isEmpty) return;
    await _saveGuidedJournalResult(result);
  }

  void _handleHealthGuidanceRequest(String healthQuestion) {
    // Capture original entry before clearing state
    final originalEntry = _guidedJournalDraft?.trim();

    // Close the guided journal flow
    setState(() {
      _showGuidedJournalFlow = false;
      _guidedJournalDraft = null;
      _isGuidedJournalLoading = false;
      _showAskPanel = true;
    });

    // Combine original entry with the health question so guidance has full context
    final query = (originalEntry != null && originalEntry.isNotEmpty)
        ? '$originalEntry\n\n$healthQuestion'
        : healthQuestion;

    // Submit the combined query to the Ask panel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _askPageKey.currentState?.submitExternalQuery(query);
    });
  }

  Widget _buildGuidedJournalLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StarboundColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: StarboundColors.stellarAqua.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(StarboundColors.stellarAqua),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tailoring your check-in...',
              style: StarboundTypography.bodySmall.copyWith(
                color: StarboundColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveGuidedJournalResult(GuidedJournalResult result) async {
    final hasText = result.rawText.trim().isNotEmpty;
    final saveMode =
        hasText ? EventSaveMode.saveJournal : EventSaveMode.saveFactorsOnly;

    try {
      await _complexityEngine.processSmartInput(
        inputText: hasText ? result.rawText : 'Guided journal check-in',
        intent: EventIntent.journal,
        saveMode: saveMode,
        factorWrites: result.factorWrites,
      );
    } catch (e) {
      debugPrint('Guided journal factor save failed: $e');
    }

    if (hasText) {
      final appState = context.read<AppState>();
      try {
        await appState.processFreeFormEntry(result.rawText);
      } catch (_) {
        final entry = FreeFormEntry(
          id: 'guided_journal_${DateTime.now().millisecondsSinceEpoch}',
          originalText: result.rawText,
          timestamp: DateTime.now(),
          classifications: const [],
          averageConfidence: 1.0,
          metadata: {
            'source': 'guided_journal_flow',
            'prompt_count': result.responses.length,
            'factor_write_count': result.factorWrites.length,
          },
          isProcessed: false,
        );
        await appState.addSimpleFreeFormEntry(entry);
      }
    }

    await _journalingReminderService.recordJournalActivity();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Check-in saved'),
          backgroundColor: StarboundColors.stellarAqua,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _updateSupportSuggestions(SmartInputResult result) {
    final suggestions = _buildSupportSuggestions(result);
    final concern = _buildSupportConcernLabel(result, suggestions);
    if (mounted) {
      setState(() {
        _supportSuggestions = suggestions;
        _supportConcernLabel = concern;
      });
    }
  }

  void _submitAsk(
    String text, {
    ComplexityResponseModel? responseModel,
    String? engineEventId,
    String? engineCreatedAt,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (mounted) {
      setState(() {
        _showAskPanel = true;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _askPageKey.currentState?.submitExternalQuery(
        trimmed,
        responseModel: responseModel,
        engineEventId: engineEventId,
        engineCreatedAt: engineCreatedAt,
      );
    });
  }

  void _navigateFromAsk(String feature) {
    switch (feature) {
      case 'habits':
      case 'journal':
        widget.onJournalPressed();
        break;
      case 'support':
        widget.onSupportPressed();
        break;
      case 'forecast':
        widget.onInsightsPressed();
        break;
      case 'actions':
        widget.onActionVaultPressed();
        break;
      default:
        break;
    }
  }

  List<SupportService> _buildSupportSuggestions(SmartInputResult result) {
    final lowerText = result.processedText.toLowerCase();
    final tags = <String>{};

    for (final topic in result.tags.healthTopics) {
      switch (topic) {
        case 'sleep':
          tags.add('sleep');
          break;
        case 'diet':
          tags.add('nutrition');
          break;
        case 'mental_health':
          tags.addAll(['stress', 'counselling']);
          break;
        case 'energy':
          tags.add('stress');
          break;
        case 'social':
          tags.add('support');
          break;
        default:
          break;
      }
    }

    for (final emotion in result.tags.emotions) {
      switch (emotion) {
        case 'anxious':
        case 'stressed':
        case 'overwhelmed':
          tags.addAll(['stress', 'counselling']);
          break;
        case 'sad':
        case 'lonely':
          tags.add('support');
          break;
        case 'tired':
          tags.add('sleep');
          break;
        default:
          break;
      }
    }

    if (lowerText.contains('rent') ||
        lowerText.contains('housing') ||
        lowerText.contains('homeless')) {
      tags.add('housing');
    }
    if (lowerText.contains('money') ||
        lowerText.contains('bills') ||
        lowerText.contains('budget')) {
      tags.add('money');
    }
    if (lowerText.contains('food') || lowerText.contains('hungry')) {
      tags.add('nutrition');
    }

    if (tags.isEmpty) {
      return const [];
    }

    final services = StarboundServices.getSampleServices();
    final filtered = services.where((service) {
      return service.tags.any(tags.contains);
    }).toList();

    filtered.sort((a, b) {
      if (a.isAvailableNow == b.isAvailableNow) {
        return a.name.compareTo(b.name);
      }
      return a.isAvailableNow ? -1 : 1;
    });

    return filtered.take(2).toList();
  }

  String? _buildSupportConcernLabel(
      SmartInputResult result, List<SupportService> suggestions) {
    if (suggestions.isEmpty) {
      return null;
    }
    final priorities = <String>[
      'stress',
      'sleep',
      'nutrition',
      'support',
      'housing',
      'money',
      'counselling',
    ];
    final allTags = suggestions.expand((service) => service.tags).toSet();
    for (final tag in priorities) {
      if (allTags.contains(tag)) {
        return _supportTagLabel(tag);
      }
    }
    return null;
  }

  String _supportTagLabel(String tag) {
    switch (tag) {
      case 'stress':
        return 'stress support';
      case 'sleep':
        return 'better sleep';
      case 'nutrition':
        return 'nutrition support';
      case 'support':
        return 'connection';
      case 'housing':
        return 'housing help';
      case 'money':
        return 'financial support';
      case 'counselling':
        return 'counselling';
      default:
        return tag.replaceAll('_', ' ');
    }
  }

  String _formatSupportNeeds(SupportService service) {
    final requirements = service.offerings
        .map((offering) => offering.requirements)
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    final needs = <String>[];
    needs.addAll(requirements);

    final contact = service.contact.toLowerCase();
    final hasAppointment = service.schedules.any((schedule) {
      final notes = schedule.notes?.toLowerCase() ?? '';
      return notes.contains('appointment');
    });
    if (hasAppointment || contact.contains('book online')) {
      needs.add('Appointment needed');
    }

    if (needs.isEmpty) {
      return 'No special requirements listed';
    }
    return needs.join(' • ');
  }

  String _formatSupportStart(SupportService service) {
    final contact = service.contact;
    if (contact.toLowerCase().startsWith('call ')) {
      return 'Call to start';
    }
    if (contact.toLowerCase().startsWith('text ')) {
      return 'Text to start';
    }
    if (contact.toLowerCase().startsWith('email ')) {
      return 'Email to start';
    }
    if (contact.toLowerCase().startsWith('visit ')) {
      return 'Visit website';
    }
    if (contact.toLowerCase().startsWith('book online')) {
      return 'Book online';
    }
    return 'Contact to start';
  }

  String _formatSupportLocation(SupportService service) {
    final location = service.location;
    if (location == null || location.address.trim().isEmpty) {
      return 'Online or phone support';
    }
    if (location.landmark != null && location.landmark!.trim().isNotEmpty) {
      return '${location.address} (${location.landmark})';
    }
    return location.address;
  }

  void _showSupportSuggestionDetails(SupportService service) {
    final concern = _supportConcernLabel ?? 'your recent note';
    showModalBottomSheet(
      context: context,
      backgroundColor: StarboundColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  service.name,
                  style: StarboundTypography.heading3.copyWith(
                    color: StarboundColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Suggested for $concern',
                  style: StarboundTypography.bodySmall.copyWith(
                    color: StarboundColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'How they can help',
                  style: StarboundTypography.caption.copyWith(
                    color: StarboundColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  service.description,
                  style: StarboundTypography.body.copyWith(
                    color: StarboundColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Where to go',
                  style: StarboundTypography.caption.copyWith(
                    color: StarboundColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatSupportLocation(service),
                  style: StarboundTypography.body.copyWith(
                    color: StarboundColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'What you need',
                  style: StarboundTypography.caption.copyWith(
                    color: StarboundColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatSupportNeeds(service),
                  style: StarboundTypography.body.copyWith(
                    color: StarboundColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'How to start',
                  style: StarboundTypography.caption.copyWith(
                    color: StarboundColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  service.contact,
                  style: StarboundTypography.body.copyWith(
                    color: StarboundColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onSupportPressed();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: StarboundColors.stellarAqua,
                  ),
                  child: const Text('Open Support Circle'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _testGeminiConnection() async {
    if (!mounted) return;
    final appState = context.read<AppState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: StarboundColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Testing OpenRouter connection…',
                    style: StarboundTypography.body.copyWith(
                      color: StarboundColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    bool initialized = false;
    String? responseText;
    try {
      initialized = await _openRouter.initialize();
      if (initialized) {
        // Get health navigation profile
        final profile = appState.healthNavigationProfile;

        responseText = await _openRouter.answerQuestion(
          'What helps with stress in the moment?',
          appState.userName,
          appState.complexityProfile.toString().split('.').last,
          memorySummary: null,
          // NEW: Health navigation context
          neighborhood: profile?.neighborhood,
          barriers: profile?.barriers,
          languages: profile?.languages,
          workSchedule: profile?.workSchedule,
          healthInterests: profile?.healthInterests,
        );
      }
    } catch (_) {
      initialized = false;
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    final bool hasResponse =
        responseText != null && responseText.trim().isNotEmpty;
    final String title = initialized && hasResponse
        ? 'OpenRouter is connected'
        : 'OpenRouter failed';
    final String message = initialized && hasResponse
        ? 'Received a live response from OpenRouter.'
        : (initialized
            ? 'OpenRouter initialized but returned an empty response.'
            : 'OpenRouter did not initialize. Check the API key and model name.');

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: StarboundColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: StarboundTypography.heading3.copyWith(
                    color: StarboundColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: StarboundTypography.body.copyWith(
                    color: StarboundColors.textSecondary,
                  ),
                ),
                if (hasResponse) ...[
                  const SizedBox(height: 12),
                  Text(
                    responseText!,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: StarboundTypography.bodySmall.copyWith(
                      color: StarboundColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: StarboundColors.stellarAqua,
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveJournalEntry(
    SmartInputResult result, {
    required bool showToast,
  }) async {
    try {
      final appState = context.read<AppState>();

      try {
        await appState.processFreeFormEntry(result.processedText);
      } catch (servicesError) {
        await Future.delayed(const Duration(seconds: 2));
        try {
          await appState.processFreeFormEntry(result.processedText);
        } catch (_) {
          final classifications = _createClassificationsFromSmartInput(result);
          final entry = FreeFormEntry(
            id: 'entry_${DateTime.now().millisecondsSinceEpoch}',
            originalText: result.processedText,
            timestamp: DateTime.now(),
            classifications: classifications,
            averageConfidence: result.confidence,
            metadata: {
              'created_from': 'smart_input_home_fallback',
              'original_intent': result.intent.toString(),
              'confidence': result.confidence,
              'reasoning': result.reasoning,
              'smart_input_tags': result.tags.toMap(),
              ...result.metadata,
            },
            isProcessed: true,
          );
          await appState.addSimpleFreeFormEntry(entry);
        }
      }

      if (showToast && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saved'),
            backgroundColor: StarboundColors.stellarAqua,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }

      if (mounted && _response != null) {
        setState(() {
          _response = _withStatusLine(_response!, 'Saved to Journal');
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save. Please try again.'),
            backgroundColor: StarboundColors.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  List<ClassificationResult> _createClassificationsFromSmartInput(
      SmartInputResult result) {
    final classifications = <ClassificationResult>[];

    for (final emotion in result.tags.emotions) {
      classifications.add(ClassificationResult(
        habitKey: 'emotion',
        habitValue: emotion,
        categoryTitle: 'Emotional State',
        categoryType: 'chance',
        confidence: 0.8,
        reasoning: 'Detected from smart input processing',
        extractedText: result.processedText,
        metadata: {'source': 'smart_input_emotion_detection'},
        sentiment: emotion,
        themes: ['emotional_wellness'],
        keywords: [emotion],
        sentimentConfidence: 0.8,
      ));
    }

    for (final topic in result.tags.healthTopics) {
      classifications.add(ClassificationResult(
        habitKey: 'health_topic',
        habitValue: topic,
        categoryTitle: 'Health Focus',
        categoryType: 'choice',
        confidence: 0.75,
        reasoning: 'Health topic detected from smart input',
        extractedText: result.processedText,
        metadata: {'source': 'smart_input_health_detection'},
        themes: ['health', topic],
        keywords: [topic],
      ));
    }

    if (result.tags.hasChoice) {
      classifications.add(ClassificationResult(
        habitKey: 'decision_structure',
        habitValue: 'choice_detected',
        categoryTitle: 'Decision Making',
        categoryType: 'choice',
        confidence: 0.7,
        reasoning: 'Choice-related content detected',
        extractedText: result.processedText,
        metadata: {'source': 'smart_input_choice_detection'},
        themes: ['decision_making'],
        keywords: ['choice', 'decision'],
      ));
    }

    if (result.tags.hasChance) {
      classifications.add(ClassificationResult(
        habitKey: 'uncertainty_structure',
        habitValue: 'chance_detected',
        categoryTitle: 'Uncertainty/Risk',
        categoryType: 'chance',
        confidence: 0.7,
        reasoning: 'Probability/uncertainty content detected',
        extractedText: result.processedText,
        metadata: {'source': 'smart_input_chance_detection'},
        themes: ['uncertainty', 'risk_assessment'],
        keywords: ['chance', 'maybe', 'might'],
      ));
    }

    if (result.tags.hasOutcome) {
      classifications.add(ClassificationResult(
        habitKey: 'outcome_structure',
        habitValue: 'outcome_detected',
        categoryTitle: 'Results/Outcomes',
        categoryType: 'choice',
        confidence: 0.7,
        reasoning: 'Outcome/result content detected',
        extractedText: result.processedText,
        metadata: {'source': 'smart_input_outcome_detection'},
        themes: ['outcomes', 'results'],
        keywords: ['result', 'outcome', 'happened'],
      ));
    }

    String intentCategory = 'General Entry';
    String intentValue = 'general';
    switch (result.intent) {
      case SmartRouteIntent.journal:
        intentCategory = 'Personal Reflection';
        intentValue = 'reflection';
        break;
      case SmartRouteIntent.guidedJournal:
        intentCategory = 'Guided Reflection';
        intentValue = 'guided_reflection';
        break;
      case SmartRouteIntent.ask:
        intentCategory = 'Question/Inquiry';
        intentValue = 'question';
        break;
      case SmartRouteIntent.both:
        intentCategory = 'Reflection + Inquiry';
        intentValue = 'both';
        break;
      case SmartRouteIntent.clarify:
        intentCategory = 'Clarification Needed';
        intentValue = 'clarify';
        break;
    }

    classifications.add(ClassificationResult(
      habitKey: 'entry_intent',
      habitValue: intentValue,
      categoryTitle: intentCategory,
      categoryType: 'choice',
      confidence: result.confidence,
      reasoning: result.reasoning,
      extractedText: result.processedText,
      metadata: {'source': 'smart_input_intent_detection'},
      themes: ['intent_classification'],
      keywords: [intentValue],
    ));

    return classifications;
  }

  HomeResponseData _withStatusLine(HomeResponseData response, String line) {
    if (response.statusLines.contains(line)) {
      return response;
    }
    final updatedLines = List<String>.from(response.statusLines)..add(line);
    return HomeResponseData(
      whatMatters: response.whatMatters,
      nextStep: response.nextStep,
      shape: response.shape,
      escalationTier: response.escalationTier,
      actionChips: response.actionChips,
      statusLines: updatedLines,
      signals: response.signals,
      rememberedSummary: response.rememberedSummary,
      memoryUsed: response.memoryUsed,
    );
  }

  void _handleClarify() {
    _inputFocusNode.requestFocus();
  }

  Future<void> _handleSave() async {
    if (_lastInputResult == null) {
      return;
    }
    await _saveJournalEntry(_lastInputResult!, showToast: true);
    if (mounted) {
      setState(() {
        _lastWasLogOnly = false;
      });
    }
  }

  void _handleNextStep() {
    if (_lastInputResult == null) {
      return;
    }
    final appState = context.read<AppState>();
    final memoryContext = _buildMemoryContext(appState, _lastRequestUseMemory);
    final decision = _responseService.buildDecision(
      _lastInputResult!,
      memoryContext: memoryContext,
      ignoreLogOnly: true,
      suppressAutoSave: true,
      complexityLevel: appState.complexityProfile,
    );

    if (mounted) {
      final int nonce = ++_responseNonce;
      setState(() {
        _response = decision.response;
        _lastWasLogOnly = false;
      });
      _maybeEnhanceResponse(
        _lastInputResult!,
        decision.response,
        memoryContext,
        nonce,
      );
    }
  }

  Future<void> _maybeEnhanceResponse(
    SmartInputResult result,
    HomeResponseData? base,
    HomeMemoryContext memoryContext,
    int nonce,
  ) async {
    if (base == null || _lastWasLogOnly) {
      return;
    }

    final enhanced = await _homeResponseAiService.enhanceResponse(
      base: base,
      input: result.processedText,
      signals: base.signals,
      memorySummary: memoryContext.summary,
    );

    if (!mounted || enhanced == null || nonce != _responseNonce) {
      return;
    }

    setState(() {
      _response = enhanced;
    });
  }

  void _handleSupport() {
    final tier = _response?.escalationTier ?? EscalationTier.none;
    if (tier == EscalationTier.crisis) {
      _showCrisisSheet();
      return;
    }
    if (tier == EscalationTier.strong) {
      _showStrongSupportSheet();
      return;
    }
    widget.onSupportPressed();
  }

  void _showWhyThis(HomeResponseData response) {
    showModalBottomSheet(
      context: context,
      backgroundColor: StarboundColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Why this?',
                  style: StarboundTypography.heading3.copyWith(
                    color: StarboundColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Signals picked up',
                  style: StarboundTypography.caption.copyWith(
                    color: StarboundColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ...response.signals.map(
                  (signal) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '- $signal',
                      style: StarboundTypography.body.copyWith(
                        color: StarboundColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                if (response.rememberedSummary != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'What was remembered',
                    style: StarboundTypography.caption.copyWith(
                      color: StarboundColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    response.rememberedSummary!,
                    style: StarboundTypography.body.copyWith(
                      color: StarboundColors.textPrimary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onActionVaultPressed();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: StarboundColors.starlightBlue,
                  ),
                  child: const Text('Edit memory'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  HomeMemoryContext _buildMemoryContext(
    AppState appState,
    bool useMemoryForRequest,
  ) {
    if (!useMemoryForRequest) {
      return const HomeMemoryContext(used: false, hasRecurrence: false);
    }
    final entries = appState.getRecentFreeFormEntries(limit: 20);
    if (entries.length < 2) {
      return const HomeMemoryContext(used: false, hasRecurrence: false);
    }

    final tagCounts = <String, int>{};
    const ignoredTags = {
      'entry_intent',
      'decision_structure',
      'uncertainty_structure',
      'outcome_structure',
      'health_topic',
      'emotion',
    };

    for (final entry in entries) {
      for (final classification in entry.classifications) {
        for (final theme in classification.themes) {
          if (ignoredTags.contains(theme)) {
            continue;
          }
          tagCounts[theme] = (tagCounts[theme] ?? 0) + 1;
        }
        if (classification.habitKey.isNotEmpty) {
          if (ignoredTags.contains(classification.habitKey)) {
            continue;
          }
          tagCounts[classification.habitKey] =
              (tagCounts[classification.habitKey] ?? 0) + 1;
        }
      }
    }

    final sorted = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.where((entry) => entry.value >= 2).take(2).toList();
    if (top.isEmpty) {
      return const HomeMemoryContext(used: false, hasRecurrence: false);
    }

    final themes = top.map((entry) => _formatTagName(entry.key)).toList();
    return HomeMemoryContext(
      used: true,
      hasRecurrence: true,
      themes: themes,
      summary: 'Recent themes: ${themes.join(', ')}',
    );
  }

  String _formatTagName(String tag) {
    return tag.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  void _showStrongSupportSheet() {
    final connections = _supportNetworkService.getPersonalConnections();
    showModalBottomSheet(
      context: context,
      backgroundColor: StarboundColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Real-time support',
                  style: StarboundTypography.heading3.copyWith(
                    color: StarboundColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This is worth real-time support. Choose one: trusted person, professional help, or local resources.',
                  style: StarboundTypography.body.copyWith(
                    color: StarboundColors.textSecondary,
                  ),
                ),
                if (connections.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Trusted people',
                    style: StarboundTypography.caption.copyWith(
                      color: StarboundColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...connections.take(2).map(_buildTrustedPersonRow),
                ],
                const SizedBox(height: 20),
                CosmicButton.primary(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onSupportPressed();
                  },
                  icon: Icons.support_agent,
                  child: const Text('Open support options'),
                ),
                const SizedBox(height: 12),
                CosmicButton.secondary(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Not now'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCrisisSheet() {
    final connections = _supportNetworkService.getPersonalConnections();
    showModalBottomSheet(
      context: context,
      backgroundColor: StarboundColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Immediate support',
                  style: StarboundTypography.heading3.copyWith(
                    color: StarboundColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'If you are in immediate danger, call emergency services now. Reach out to a trusted person right away.',
                  style: StarboundTypography.body.copyWith(
                    color: StarboundColors.textSecondary,
                  ),
                ),
                if (connections.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Trusted people',
                    style: StarboundTypography.caption.copyWith(
                      color: StarboundColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...connections.take(2).map(_buildTrustedPersonRow),
                ],
                const SizedBox(height: 20),
                CosmicButton.primary(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onSupportPressed();
                  },
                  icon: Icons.phone_in_talk,
                  child: const Text('Open emergency support'),
                ),
                const SizedBox(height: 12),
                CosmicButton.secondary(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Not now'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrustedPersonRow(SupportService service) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CosmicGlassPanel.surface(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Text(
              service.icon,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: StarboundTypography.body.copyWith(
                      color: StarboundColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    service.contact,
                    style: StarboundTypography.bodySmall.copyWith(
                      color: StarboundColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _launchContact(service.contact),
              style: TextButton.styleFrom(
                foregroundColor: StarboundColors.stellarAqua,
              ),
              child: const Text('Contact'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchContact(String contact) async {
    Uri? uri;

    if (contact.toLowerCase().startsWith('call ')) {
      final phone = contact.substring(5).replaceAll(' ', '');
      uri = Uri(scheme: 'tel', path: phone);
    } else if (contact.toLowerCase().startsWith('email ')) {
      final email = contact.substring(6);
      uri = Uri(scheme: 'mailto', path: email);
    } else if (contact.toLowerCase().startsWith('text ')) {
      final phone = contact.substring(5).replaceAll(' ', '');
      uri = Uri(scheme: 'sms', path: phone);
    } else if (contact.toLowerCase().startsWith('visit ')) {
      final url = contact.substring(6);
      uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    } else if (contact.toLowerCase().startsWith('book online at ')) {
      final url = contact.substring(15);
      uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    }

    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await Clipboard.setData(ClipboardData(text: contact));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Contact info copied to clipboard: $contact'),
            backgroundColor: StarboundColors.stellarAqua,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final bool hasMemory = appState.freeFormEntries.isNotEmpty;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: StarboundColors.background,
    ));

    return Scaffold(
      backgroundColor: StarboundColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: CosmicParallaxField(
              scrollOffset: 0,
              baseColor: StarboundColors.deepSpace,
            ),
          ),
          SafeArea(
            child: StarboundBreakpoints.responsiveContainer(
              context: context,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 20 * context.spacingScale,
                  vertical: 24 * context.spacingScale,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/images/Logo.png',
                        height: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SmartInputWidget(
                      onInputProcessed: _handleSmartInput,
                      onGuidedJournalRequested: _startGuidedJournalFlow,
                      placeholder: 'What is on your mind today?',
                      showIntentIndicator: false,
                      controller: _inputController,
                      focusNode: _inputFocusNode,
                    ),
                    if (_showGuidedJournalFlow) ...[
                      const SizedBox(height: 16),
                      if (_isGuidedJournalLoading)
                        _buildGuidedJournalLoadingCard()
                      else
                        GuidedJournalFlow(
                          key: ValueKey(
                              'guided_journal_$_guidedJournalSessionId'),
                          prompts: _guidedJournalPrompts.isNotEmpty
                              ? _guidedJournalPrompts
                              : _guidedJournalService.buildV1Prompts(),
                          service: _guidedJournalService,
                          initialEventText: _guidedJournalDraft,
                          accentColor: StarboundColors.stellarAqua,
                          margin: EdgeInsets.zero,
                          useSafeArea: false,
                          onCompleted: _handleGuidedJournalCompleted,
                          onHealthGuidanceRequested: _handleHealthGuidanceRequest,
                        ),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _testGeminiConnection,
                        style: TextButton.styleFrom(
                          foregroundColor: StarboundColors.stellarAqua,
                        ),
                        child: const Text('Test OpenRouter'),
                      ),
                    ),
                    if (hasMemory) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox.adaptive(
                            value: _useMemoryForRequest,
                            activeColor: StarboundColors.stellarAqua,
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _useMemoryForRequest = value;
                              });
                            },
                          ),
                          Expanded(
                            child: Text(
                              'Use my past notes for this',
                              style: StarboundTypography.bodySmall.copyWith(
                                color: StarboundColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_lastInputText != null &&
                        _lastInputText!.trim().isNotEmpty) ...[
                      SizedBox(height: 16 * context.spacingScale),
                      _buildUserEntryCard(),
                    ],
                    if (_supportSuggestions.isNotEmpty) ...[
                      SizedBox(height: 16 * context.spacingScale),
                      _buildSupportSuggestionCard(),
                    ],
                    if (_showAskPanel) ...[
                      SizedBox(height: 24 * context.spacingScale),
                      Text(
                        'Ask Starbound',
                        style: StarboundTypography.heading3.copyWith(
                          color: StarboundColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AskPage(
                        key: _askPageKey,
                        embedded: true,
                        showSearchBar: false,
                        onGoBack: () {},
                        onSubmit: (_) {},
                        onNavigateToFeature: _navigateFromAsk,
                      ),
                    ],
                    if (_response != null) ...[
                      SizedBox(height: 16 * context.spacingScale),
                      HomeResponseCard(
                        response: _response!,
                        onWhyThis: () => _showWhyThis(_response!),
                      ),
                      if (_response!.actionChips.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildActionChips(_response!),
                      ],
                    ] else if (_lastInputResult != null) ...[
                      SizedBox(height: 16 * context.spacingScale),
                      _buildBridgeCard(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSupportSuggestionCard() {
    if (_supportSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    final service = _supportSuggestions.first;
    final concern = _supportConcernLabel ?? 'a current concern';

    return GestureDetector(
      onTap: () => _showSupportSuggestionDetails(service),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: StarboundColors.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: StarboundColors.cosmicWhite.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Support Circle suggestion',
              style: StarboundTypography.caption.copyWith(
                color: StarboundColors.textSecondary,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: StarboundColors.deepSpace.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: StarboundColors.cosmicWhite.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    service.icon,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: StarboundTypography.bodyLarge.copyWith(
                          color: StarboundColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Suggested for $concern',
                        style: StarboundTypography.bodySmall.copyWith(
                          color: StarboundColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  service.isAvailableNow ? 'Open now' : 'Closed',
                  style: StarboundTypography.bodySmall.copyWith(
                    color: service.isAvailableNow
                        ? StarboundColors.stellarAqua
                        : StarboundColors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              service.description,
              style: StarboundTypography.bodySmall.copyWith(
                color: StarboundColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Text(
              'What you need: ${_formatSupportNeeds(service)}',
              style: StarboundTypography.bodySmall.copyWith(
                color: StarboundColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'How to start: ${_formatSupportStart(service)}',
              style: StarboundTypography.bodySmall.copyWith(
                color: StarboundColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserEntryCard() {
    final text = _lastInputText?.trim() ?? '';
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StarboundColors.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: StarboundColors.cosmicWhite.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You wrote',
            style: StarboundTypography.caption.copyWith(
              color: StarboundColors.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: StarboundTypography.bodyLarge.copyWith(
              color: StarboundColors.textPrimary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBridgeCard() {
    if (_lastInputResult == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StarboundColors.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: StarboundColors.cosmicWhite.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next steps',
            style: StarboundTypography.caption.copyWith(
              color: StarboundColors.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              CosmicChip.action(
                label: 'Save to Journal',
                onTap: () {
                  if (_lastInputResult == null) return;
                  _saveJournalEntry(_lastInputResult!, showToast: true);
                },
                color: StarboundColors.stellarAqua,
              ),
              CosmicChip.action(
                label: 'Support Circle',
                onTap: widget.onSupportPressed,
                color: StarboundColors.cosmicPink,
              ),
              CosmicChip.action(
                label: 'Action Vault',
                onTap: widget.onActionVaultPressed,
                color: StarboundColors.starlightBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionChips(HomeResponseData response) {
    if (response.actionChips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: response.actionChips.map((chip) {
        switch (chip) {
          case HomeActionChip.clarify:
            return CosmicChip.action(
              label: 'Clarify',
              icon: Icons.help_outline_rounded,
              color: StarboundColors.starlightBlue,
              onTap: _handleClarify,
            );
          case HomeActionChip.save:
            return CosmicChip.action(
              label: 'Save',
              icon: Icons.bookmark_border,
              color: StarboundColors.stellarAqua,
              onTap: _handleSave,
            );
          case HomeActionChip.getSupport:
            return CosmicChip.action(
              label: 'Get support',
              icon: Icons.support_agent,
              color: StarboundColors.solarOrange,
              onTap: _handleSupport,
            );
          case HomeActionChip.justSave:
            return CosmicChip.action(
              label: 'Just save',
              icon: Icons.bookmark_added,
              color: StarboundColors.stellarAqua,
              onTap: _handleSave,
            );
          case HomeActionChip.nextStep:
            return CosmicChip.action(
              label: 'Give me a next step',
              icon: Icons.arrow_forward,
              color: StarboundColors.starlightBlue,
              onTap: _handleNextStep,
            );
        }
      }).toList(),
    );
  }
}
