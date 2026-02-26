import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../utils/response_filter.dart';

enum _QuestionCategory {
  stress,
  food,
  sleep,
  energy,
  mood,
  exercise,
  motivation,
  general,
}

/// Simple AI Service for question answering
class SimpleAIService {
  static final SimpleAIService _instance = SimpleAIService._internal();
  factory SimpleAIService() => _instance;
  SimpleAIService._internal();

  final Random _random = Random();
  
  /// Answer general questions using AI-like responses
  Future<String> answerQuestion({
    required String question,
    required String userName,
    required String complexityProfile,
    required Map<String, dynamic> context,
  }) async {
    // Simulate AI processing time
    await Future.delayed(Duration(milliseconds: 1000 + _random.nextInt(1500)));
    
    String rawResponse;
    try {
      rawResponse = _generateIntelligentResponse(
          question, userName, complexityProfile, context);
    } catch (e) {
      if (kDebugMode) {
        print('Question answering failed: $e');
      }
      rawResponse = _fallbackResponse(question, complexityProfile);
    }

    final structured = _buildStructuredResponse(
      question: question,
      rawResponse: rawResponse,
    );

    return jsonEncode(structured);
  }

  String _generateIntelligentResponse(String question, String userName, String complexityProfile, Map<String, dynamic> context) {
    final questionLower = question.toLowerCase();
    final name = userName.isNotEmpty ? userName : 'friend';
    final category = _detectCategory(questionLower);

    switch (category) {
      case _QuestionCategory.stress:
        return _generateStressResponse(name, complexityProfile, questionLower);
      case _QuestionCategory.food:
        return _generateFoodResponse(name, complexityProfile, questionLower);
      case _QuestionCategory.sleep:
        return _generateSleepResponse(name, complexityProfile, questionLower);
      case _QuestionCategory.energy:
        return _generateEnergyResponse(name, complexityProfile, questionLower);
      case _QuestionCategory.mood:
        return _generateMoodResponse(name, complexityProfile, questionLower);
      case _QuestionCategory.exercise:
        return _generateExerciseResponse(name, complexityProfile, questionLower);
      case _QuestionCategory.motivation:
        return _generateMotivationResponse(name, complexityProfile, questionLower);
      case _QuestionCategory.general:
        return _generateGeneralResponse(name, complexityProfile, questionLower);
    }
  }

  Map<String, dynamic> _buildStructuredResponse({
    required String question,
    required String rawResponse,
  }) {
    final questionLower = question.toLowerCase();
    final category = _detectCategory(questionLower);
    final understandingRaw = _extractUnderstanding(rawResponse);
    final understanding = ResponseFilter.processResponse(understandingRaw);

    final possibleCauses = _buildPossibleCauses(category)
        .map(ResponseFilter.processResponse)
        .toList();

    final stepTexts = _buildImmediateSteps(
      rawResponse: rawResponse,
      category: category,
    ).map(ResponseFilter.processResponse).toList();

    final immediateSteps = <Map<String, dynamic>>[];
    for (var i = 0; i < stepTexts.length; i++) {
      final text = stepTexts[i];
      immediateSteps.add({
        'step_number': i + 1,
        'title': text,
        'description': text,
        'estimated_time': _estimateStepTime(i),
        'theme': _inferStepTheme(text),
      });
    }

    final whenToSeekCare = _buildWhenToSeekCare(category);
    final followUpSuggestions = _buildFollowUpSuggestions(category)
        .map(ResponseFilter.processResponse)
        .toList();
    final resourceNeeds = _buildResourceNeeds(category, stepTexts);

    return {
      'understanding': understanding,
      'possible_causes': possibleCauses,
      'immediate_steps': immediateSteps,
      'when_to_seek_care': whenToSeekCare,
      'resource_needs': resourceNeeds,
      'follow_up_suggestions': followUpSuggestions,
    };
  }

  _QuestionCategory _detectCategory(String questionLower) {
    if (questionLower.contains('stress') ||
        questionLower.contains('anxious') ||
        questionLower.contains('overwhelmed')) {
      return _QuestionCategory.stress;
    }
    if (questionLower.contains('eat') ||
        questionLower.contains('food') ||
        questionLower.contains('hungry')) {
      return _QuestionCategory.food;
    }
    if (questionLower.contains('sleep') ||
        questionLower.contains('tired') ||
        questionLower.contains('rest')) {
      return _QuestionCategory.sleep;
    }
    if (questionLower.contains('energy') ||
        questionLower.contains('exhausted') ||
        questionLower.contains('fatigue')) {
      return _QuestionCategory.energy;
    }
    if (questionLower.contains('mood') ||
        questionLower.contains('sad') ||
        questionLower.contains('happy') ||
        questionLower.contains('feeling')) {
      return _QuestionCategory.mood;
    }
    if (questionLower.contains('exercise') ||
        questionLower.contains('workout') ||
        questionLower.contains('movement')) {
      return _QuestionCategory.exercise;
    }
    if (questionLower.contains('motivat') ||
        questionLower.contains('inspire') ||
        questionLower.contains('encourage')) {
      return _QuestionCategory.motivation;
    }
    return _QuestionCategory.general;
  }

  String _extractUnderstanding(String rawResponse) {
    final trimmed = rawResponse.trim();
    if (trimmed.isEmpty) {
      return 'Here are a few options to consider.';
    }

    final stepMatch = RegExp(r'\n\n\*\*Step\s*\d+:', multiLine: true)
        .firstMatch(trimmed);
    final beforeSteps =
        stepMatch == null ? trimmed : trimmed.substring(0, stepMatch.start);
    final firstParagraph = beforeSteps
        .split(RegExp(r'\n\s*\n'))
        .first
        .trim();

    return firstParagraph.isEmpty
        ? 'Here are a few options to consider.'
        : firstParagraph;
  }

  List<String> _buildPossibleCauses(_QuestionCategory category) {
    List<String> causes;
    switch (category) {
      case _QuestionCategory.stress:
        causes = [
          'High stress load or ongoing demands can keep your system on alert.',
          'Low sleep, skipped meals, or dehydration can amplify stress signals.',
        ];
      case _QuestionCategory.food:
        causes = [
          'Irregular meals or low protein can lead to energy dips.',
          'Stress or a busy schedule can affect appetite and food choices.',
        ];
      case _QuestionCategory.sleep:
        causes = [
          'Irregular sleep timing or screen exposure can disrupt sleep cycles.',
          'Stress and racing thoughts can make it harder to wind down.',
        ];
      case _QuestionCategory.energy:
        causes = [
          'Sleep debt or inconsistent meals can drive low energy.',
          'Low movement, dehydration, or stress can contribute to fatigue.',
        ];
      case _QuestionCategory.mood:
        causes = [
          'Stress, isolation, or low recovery time can affect mood.',
          'Sleep and nutrition changes can shift emotional balance.',
        ];
      case _QuestionCategory.exercise:
        causes = [
          'Overdoing it early or inconsistent routines can stall progress.',
          'Low recovery, hydration, or sleep can affect performance.',
        ];
      case _QuestionCategory.motivation:
        causes = [
          'Goals that feel too big or unclear can drain motivation.',
          'Low energy or decision fatigue can make action harder.',
        ];
      case _QuestionCategory.general:
        causes = [
          'Multiple factors can contribute, including stress, sleep, and routines.',
          'Recent changes in schedule or workload can shift how you feel.',
        ];
    }

    causes.add('Only a doctor can diagnose for certain if there is an underlying medical cause.');
    return causes;
  }

  List<String> _buildImmediateSteps({
    required String rawResponse,
    required _QuestionCategory category,
  }) {
    final extracted = _extractStepsFromResponse(rawResponse);
    final steps = <String>[...extracted];
    if (steps.length >= 3) {
      return steps.take(3).toList();
    }

    final defaults = _defaultStepsForCategory(category);
    for (final fallback in defaults) {
      if (steps.length >= 3) break;
      if (steps.any((step) => step.toLowerCase() == fallback.toLowerCase())) {
        continue;
      }
      steps.add(fallback);
    }

    return steps.take(3).toList();
  }

  List<String> _extractStepsFromResponse(String rawResponse) {
    final steps = <String>[];
    final boldStepPattern =
        RegExp(r'\*\*Step\s*\d+:\s*([^*]+)\*\*\s*([^\n]+)?', multiLine: true);
    for (final match in boldStepPattern.allMatches(rawResponse)) {
      final title = match.group(1)?.trim() ?? '';
      final detail = match.group(2)?.trim() ?? '';
      if (title.isEmpty) continue;
      final text = detail.isEmpty ? title : '$title - $detail';
      steps.add(text);
    }

    if (steps.isNotEmpty) {
      return steps;
    }

    final plainStepPattern =
        RegExp(r'^\s*Step\s*\d+:\s*(.+)$', multiLine: true);
    for (final match in plainStepPattern.allMatches(rawResponse)) {
      final text = match.group(1)?.trim();
      if (text != null && text.isNotEmpty) {
        steps.add(text);
      }
    }

    return steps;
  }

  List<String> _defaultStepsForCategory(_QuestionCategory category) {
    switch (category) {
      case _QuestionCategory.stress:
        return [
          'Take three slow breaths and relax your shoulders.',
          'Drink water or have a small snack if you have not eaten.',
          'Do a 2-minute reset: stretch, step outside, or look away from screens.',
        ];
      case _QuestionCategory.food:
        return [
          'Choose a simple meal with protein and a carb.',
          'Add one fruit or vegetable if it is available.',
          'Drink a glass of water and pause before the next bite.',
        ];
      case _QuestionCategory.sleep:
        return [
          'Dim lights and reduce screens for 30 minutes before bed.',
          'Try a short wind-down routine like stretching or breathing.',
          'Write down one worry so your mind can let it go for now.',
        ];
      case _QuestionCategory.energy:
        return [
          'Have water and a small protein snack.',
          'Take a 5-minute walk or gentle stretch.',
          'Aim for a consistent bedtime tonight if possible.',
        ];
      case _QuestionCategory.mood:
        return [
          'Name the feeling and one thing that might be influencing it.',
          'Do a quick grounding activity like five deep breaths.',
          'Reach out to one supportive person if that feels safe.',
        ];
      case _QuestionCategory.exercise:
        return [
          'Start with 5 minutes of movement at an easy pace.',
          'Warm up gently and stop if anything hurts.',
          'Plan the next session at the same low effort level.',
        ];
      case _QuestionCategory.motivation:
        return [
          'Pick one tiny action you can finish in 2 minutes.',
          'Set a simple reminder or cue for that action.',
          'Track the win today, even if it is small.',
        ];
      case _QuestionCategory.general:
        return [
          'Pick one small action that feels manageable today.',
          'Write down the main goal in one simple sentence.',
          'Check in again after a few days and adjust.',
        ];
    }
  }

  Map<String, String> _buildWhenToSeekCare(_QuestionCategory category) {
    switch (category) {
      case _QuestionCategory.mood:
      case _QuestionCategory.stress:
        return {
          'routine':
              'Check in with a GP if this keeps affecting daily life for more than a week.',
          'urgent':
              'Seek same-day help if symptoms feel severe, rapidly worsen, or you feel unable to cope.',
          'emergency':
              'Call 000 if you feel unsafe or at risk of harm.',
        };
      default:
        return {
          'routine':
              'See a GP if this persists for more than a few days or impacts daily life.',
          'urgent':
              'See a doctor today if symptoms are severe, worsening, or new.',
          'emergency':
              'Call 000 if you have severe symptoms like chest pain, trouble breathing, confusion, or fainting.',
        };
    }
  }

  List<String> _buildFollowUpSuggestions(_QuestionCategory category) {
    switch (category) {
      case _QuestionCategory.sleep:
        return [
          'Track bedtime, wake time, and how rested you feel for 3-5 days.',
          'If sleep does not improve after a week, consider talking with a GP.',
        ];
      case _QuestionCategory.food:
        return [
          'Track meals, hunger, and energy for 3 days.',
          'If appetite changes persist, check in with a GP.',
        ];
      case _QuestionCategory.energy:
        return [
          'Track energy highs and lows, meals, and sleep for 3 days.',
          'If fatigue is persistent or severe, consider a GP check.',
        ];
      case _QuestionCategory.mood:
        return [
          'Track mood, triggers, and supports you tried.',
          'If low mood persists or feels severe, reach out for professional support.',
        ];
      case _QuestionCategory.exercise:
        return [
          'Track movement type and how your body feels the next day.',
          'If pain persists or worsens, check in with a GP or physio.',
        ];
      case _QuestionCategory.motivation:
        return [
          'Track one small win each day for a week.',
          'If motivation stays very low, consider a GP check-in.',
        ];
      case _QuestionCategory.stress:
        return [
          'Track stress level (1-10), sleep, and caffeine for 3 days.',
          'If stress stays high, consider talking with a GP or counselor.',
        ];
      case _QuestionCategory.general:
        return [
          'Track the main factors you think matter for 3-5 days.',
          'Check back in after a week and adjust the smallest step.',
        ];
    }
  }

  List<String> _buildResourceNeeds(
    _QuestionCategory category,
    List<String> immediateSteps,
  ) {
    final resources = <String>{'journaling', 'habit-tracking'};
    if (category == _QuestionCategory.mood || category == _QuestionCategory.stress) {
      resources.add('mood-tracking');
    }
    final stepText = immediateSteps.join(' ').toLowerCase();
    if (stepText.contains('gp') ||
        stepText.contains('doctor') ||
        stepText.contains('telehealth') ||
        stepText.contains('clinic')) {
      resources.add('telehealth');
    }
    return resources.toList();
  }

  String _estimateStepTime(int index) {
    switch (index) {
      case 0:
        return '2-5 min';
      case 1:
        return '5-10 min';
      default:
        return 'today';
    }
  }

  String _inferStepTheme(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('track') ||
        lower.contains('journal') ||
        lower.contains('note')) {
      return 'monitoring';
    }
    if (lower.contains('gp') ||
        lower.contains('doctor') ||
        lower.contains('clinic') ||
        lower.contains('telehealth')) {
      return 'healthcare_access';
    }
    return 'self_care';
  }

  String _generateStressResponse(String name, String complexityProfile, String question) {
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return "Research shows that stress responses are completely normal when managing significant challenges. When stress feels overwhelming, focusing on breath for a few moments can help.\n\n**Step 1: Take three deep breaths** Studies indicate that even three deep breaths can help your nervous system begin to calm.\n\n**Step 2: Find a quiet moment** Even 30 seconds of stillness can make a difference when everything feels overwhelming.";
      case 'overloaded':
        return "Based on behavioral science, stress when you're already managing multiple demands can feel impossible. Evidence suggests small actions can help your body reset when everything feels overwhelming.\n\n**Step 1: Try a micro-action** Focus on something simple like drinking water or stepping outside for 30 seconds.\n\n**Step 2: Take one thing off your plate** Identify one small task you can delay or delegate today.";
      case 'trying':
        return "Research indicates that managing stress while working on other challenges demonstrates significant resilience. When stress hits, grounding techniques can help anchor attention in the present moment.\n\n**Step 1: Try the 5-4-3-2-1 technique** Name 5 things you can see, 4 you can touch, 3 you can hear, 2 you can smell, 1 you can taste.\n\n**Step 2: Schedule a 5-minute break** Set a timer and do something that brings you comfort during those 5 minutes.";
      default:
        return "Studies show that stress is your body's signal that something needs attention. Sometimes it involves setting boundaries, other times addressing basic needs like sleep and nutrition.\n\n**Step 1: Identify the stress source** Take a moment to recognize what's causing the most stress right now.\n\n**Step 2: Choose one small change** Pick the most manageable adjustment you could make to reduce this stress.\n\n**Step 3: Practice self-compassion** Remember that feeling stressed doesn't mean you're failing - it means you're human.";
    }
  }

  String _generateFoodResponse(String name, String complexityProfile, String question) {
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return "Research shows that during high-stress periods, any nutrition is better than none. Rather than focusing on perfect nutrition, prioritize foods that feel manageable and provide energy.\n\n**Step 1: Choose simple options** Keep easy foods nearby like toast, bananas, or crackers that require minimal preparation.\n\n**Step 2: Eat something now** If you haven't eaten recently, have even a small snack to maintain your energy.";
      case 'overloaded':
        return "Studies indicate that when overwhelmed, even food decisions can feel challenging. Your body needs consistent fuel to cope with multiple demands.\n\n**Step 1: Stock simple options** Keep crackers, fruit, nuts, or anything requiring minimal preparation within easy reach.\n\n**Step 2: Set eating reminders** Use your phone to remind yourself to eat every 3-4 hours, even if it's just a small snack.";
      case 'trying':
        return "Evidence suggests that nutrition can feel complicated when managing other challenges. Small, consistent choices often prove more sustainable than dramatic changes.\n\n**Step 1: Start with protein** Include a protein source like eggs, yogurt, or nuts in your next meal.\n\n**Step 2: Add something fresh** Include fruit or vegetables when possible, but don't stress if it's not every meal.\n\n**Step 3: Stay hydrated** Keep water nearby and sip regularly throughout the day.";
      default:
        return "When you're unsure what to eat, research suggests considering what your body needs right now. Are you seeking energy, comfort, or nourishment? Balancing protein, healthy fats, and complex carbs tends to be most effective.\n\n**Step 1: Include protein and complex carbs** Try combinations like apple with almond butter, or whole grain toast with avocado.\n\n**Step 2: Add mood-supporting foods** Studies show foods rich in magnesium (leafy greens, nuts) and omega-3s (salmon, walnuts) can help during stress.\n\n**Step 3: Listen to your body** Notice how different foods make you feel and adjust accordingly.";
    }
  }

  String _generateSleepResponse(String name, String complexityProfile, String question) {
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return "Research shows that during high-stress periods, any rest you can get matters.\n\n**Step 1: Prioritize rest over perfect sleep** Rather than focusing on perfect sleep, prioritize resting your body and mind when possible.\n\n**Step 2: Try gentle rest** Studies indicate that even lying down with eyes closed for 20 minutes can help restore some energy.\n\n**Step 3: Be compassionate with yourself** Remember that rest is productive, especially during challenging times.";
      case 'overloaded':
        return "Evidence suggests that sleep can feel impossible when your mind is racing.\n\n**Step 1: Create a simple wind-down routine** Try dimming lights, removing your phone from the bedroom, and focusing on slow, deep breathing.\n\n**Step 2: Practice calming techniques** Research shows that even 10 minutes of this can help signal to your body that it's time to rest.\n\n**Step 3: Start small** Pick just one element of this routine to begin with tonight.";
      case 'trying':
        return "Studies show that sleep challenges are common when managing multiple demands.\n\n**Step 1: Try the 3-2-1 rule** No food 3 hours before bed, no liquids 2 hours before, and no screens 1 hour before.\n\n**Step 2: Start with one change** Research suggests that implementing just one of these changes can make a significant difference.\n\n**Step 3: Track what works** Notice which change feels most manageable and stick with it for a week.";
      default:
        return "Studies consistently show that quality sleep is foundational for managing stress and maintaining energy.\n\n**Step 1: Optimize your sleep environment** Make your bedroom cool, dark, and quiet.\n\n**Step 2: Develop a bedtime routine** Consider what activities help you wind down 30-60 minutes before sleep.\n\n**Step 3: Address sleep disruptors** Research indicates that stress affects sleep, and poor sleep increases stress - identify what might be disrupting your sleep.\n\n**Step 4: Make small changes** Breaking this cycle with small, consistent changes can help significantly.";
    }
  }

  String _generateEnergyResponse(String name, String complexityProfile, String question) {
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return "Research shows that during high-stress periods, energy conservation is crucial. You may want to focus on the basics: any sleep you can get, staying hydrated, and eating when possible. Studies indicate that conserving energy rather than pushing beyond what's necessary is actually an adaptive strategy.";
      case 'overloaded':
        return "Evidence suggests that low energy when overwhelmed is a normal physiological response. One approach could be micro-breaks: 2 minutes of deep breathing, a short walk, or stretching. Research shows that even the smallest actions can provide enough energy restoration to continue.";
      case 'trying':
        return "Studies show that energy fluctuations are normal when working on behavioral change. You may want to try pairing a protein with a complex carb (like apple with almond butter), staying hydrated, and taking short breaks between tasks. Your body needs consistent fuel when managing multiple challenges.";
      default:
        return "Research indicates that sustainable energy comes from multiple factors working together: quality sleep, balanced nutrition, regular movement, stress management, and adequate hydration. Rather than addressing everything simultaneously, you may want to pick one area that feels most manageable and focus there first.";
    }
  }

  String _generateMoodResponse(String name, String complexityProfile, String question) {
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return "Research validates that all feelings are normal responses to challenging circumstances. When you're managing significant stress, mood difficulties are a natural physiological response. Studies show that any small act of self-compassion represents meaningful progress.";
      case 'overloaded':
        return "Evidence suggests that mood fluctuations when overwhelmed are your body's way of processing stress. One approach could be practicing self-compassion. Research indicates that simply acknowledging 'this is difficult and efforts matter' can provide some relief.";
      case 'trying':
        return "Studies show that mood changes while navigating challenges are completely normal. You may want to consider what supports emotional wellbeing: connection with others, time in nature, creative expression, or gentle movement. Research suggests that even 5 minutes of pleasant activity can have beneficial effects.";
      default:
        return "Research shows that mood is influenced by multiple factors including sleep, nutrition, exercise, stress levels, and social connection. You may want to notice patterns - what tends to lift your mood and what tends to drain it? Studies indicate that small, consistent practices often have more impact than dramatic changes.";
    }
  }

  String _generateExerciseResponse(String name, String complexityProfile, String question) {
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return "Research shows that during high-stress periods, any movement represents meaningful self-care. Even stretching in bed, walking to the kitchen, or doing arm circles counts as beneficial activity. Studies indicate that your body is working hard to cope - any movement you can manage has value.";
      case 'overloaded':
        return "Evidence suggests that formal exercise might feel impossible when overwhelmed, and that's a normal response. One approach could be integrating tiny movements into your day: stretching while waiting for coffee, taking stairs, or doing gentle neck rolls. Research shows that movement doesn't need to be scheduled to provide benefits.";
      case 'trying':
        return "Studies indicate that beginning with movement while managing challenges is beneficial. You may want to try the 2-minute rule: committing to just 2 minutes of movement daily. This could be dancing to one song, walking around the block, or doing stretches. Research shows that success builds on itself.";
      default:
        return "Research consistently shows that movement benefits both body and mind. You may want to find what feels good for you - walking, dancing, yoga, swimming, or playing sports. Studies suggest that the most effective exercise is one you'll actually do. Starting small and building gradually, focusing on how movement makes you feel rather than perfect form, tends to be most sustainable.";
    }
  }

  String _generateMotivationResponse(String name, String complexityProfile, String question) {
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return "Research shows that seeking motivation while managing survival needs demonstrates remarkable resilience. Studies indicate that during high-stress periods, motivation isn't about large goals - it's about recognizing that you're still engaging, still trying, still caring. This represents significant strength.";
      case 'overloaded':
        return "Evidence suggests that when overwhelmed, motivation isn't about doing more - it's about recognizing existing efforts. Research shows that sometimes the most motivating approach is acknowledging your current effort and giving yourself permission to rest.";
      case 'trying':
        return "Studies show that motivation often builds from small wins accumulating over time. You may want to celebrate tiny victories - drinking water, taking a shower, reaching out for support. Research indicates that progress isn't always linear, and that's completely normal. You're likely doing better than you realize.";
      default:
        return "Research indicates that sustainable motivation comes from connecting with your values and breaking large goals into manageable steps. You may want to remember your 'why' - what matters most to you? Then consider: what's the smallest step you can take today toward that? Studies show that motivation often follows action, not the other way around.";
    }
  }

  String _generateGeneralResponse(String name, String complexityProfile, String question) {
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return "Research shows that support without judgment is most effective during high-stress periods.\n\n**Step 1: Acknowledge your strength** Reaching out demonstrates considerable strength - you're already taking a positive step.\n\n**Step 2: Focus on what's manageable** When managing survival needs, every moment of self-care has significant value.\n\n**Step 3: Start small** Choose one thing that feels manageable right now, even if it's tiny.";
      case 'overloaded':
        return "Evidence suggests that managing multiple demands is exhausting, and feeling overwhelmed is completely normal.\n\n**Step 1: Identify what's most essential** Focus on what's most crucial today rather than everything at once.\n\n**Step 2: Give yourself permission to prioritize** Research shows you don't need to have everything figured out simultaneously.\n\n**Step 3: Take one small action** Pick the smallest meaningful step you can take right now.";
      case 'trying':
        return "Studies show that reaching out while navigating challenges requires real courage.\n\n**Step 1: Recognize your progress** Change is difficult, and it's normal if progress feels slow or uncertain.\n\n**Step 2: Identify what feels doable** Consider what small change or support would feel most helpful right now.\n\n**Step 3: Build on what works** Focus on sustainable actions rather than dramatic changes.";
      default:
        return "Research shows that wellness journeys benefit from multiple types of support.\n\n**Step 1: Assess what you need** Consider whether you need practical guidance, emotional support, or help breaking down challenges.\n\n**Step 2: Start with one area** Choose the area that feels most important or manageable to address first.\n\n**Step 3: Take a small action** Identify one concrete step you can take today toward that goal.\n\n**Step 4: Build momentum** Use success from small steps to tackle larger challenges gradually.";
    }
  }

  String _fallbackResponse(String question, String complexityProfile) {
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return "Based on what you've shared, you're navigating a challenging period. Research shows that reaching out demonstrates significant strength.\n\n**Step 1: Acknowledge your courage** Asking for help demonstrates significant strength, especially during difficult times.\n\n**Step 2: Focus on basics** Prioritize sleep, nutrition, and hydration when possible - even small amounts help.\n\n**Step 3: Take it one moment at a time** You don't need to solve everything right now - just focus on what feels manageable today.";
      case 'overloaded':
        return "Evidence suggests that managing multiple demands is exhausting. Research shows even the smallest step has value.\n\n**Step 1: Prioritize today's essentials** Focus on what absolutely must be done today, and give yourself permission to delay the rest.\n\n**Step 2: Take micro-breaks** Even 2 minutes of deep breathing or stepping outside can help reset your energy.\n\n**Step 3: Ask for support** Consider what tasks could be delegated, postponed, or simplified.";
      case 'trying':
        return "Studies show that working to manage challenges requires real courage. I want to help you identify what feels doable right now.\n\n**Step 1: Recognize your progress** Change is difficult, and you're already taking positive steps by reaching out.\n\n**Step 2: Start small** Consider what single, manageable action might support your wellbeing today.\n\n**Step 3: Build gradually** Focus on sustainable changes rather than dramatic shifts - small steps compound over time.";
      default:
        return "I understand you have a health-related question. While I work best with topics like stress, sleep, nutrition, or energy, I want to help however I can.\n\n**Step 1: Identify your main concern** What aspect of your health or wellbeing feels most important to address right now?\n\n**Step 2: Start with basics** Research shows that small, consistent changes in sleep, nutrition, or movement often create meaningful improvement.\n\n**Step 3: Take one small action** What feels most manageable to start with today?";
    }
  }
}
