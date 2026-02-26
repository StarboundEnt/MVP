class ResponseFilter {
  static const Map<String, String> _anthropomorphicReplacements = {
    // First person statements
    'I think': 'It seems',
    'I believe': 'It appears that',
    'I recommend': 'You may want to consider',
    'I suggest': 'One approach could be',
    'I understand': 'Based on what you shared',
    'I can see': 'It appears that',
    'I can sense': 'It seems that',
    'I hear': 'What you\'ve described suggests',
    'I know': 'It\'s clear that',
    'I\'m here for you': 'Support is available',
    'I\'m here to help': 'Resources are available to help',
    'I\'m ready to help': 'Help is available',
    'I\'m sorry to hear': 'It sounds like',
    'sorry to hear': 'It sounds like',
    'I hope': 'It may help to',

    // Emotional empathy statements
    'I feel': 'Many people experience',
    'I care': 'Your wellbeing matters',
    'I worry': 'It\'s important to consider',
    'I\'m concerned': 'This situation warrants attention',

    // Personal opinions/judgments
    'I\'m proud': 'This represents progress',
    'I appreciate': 'This shows strength',
    'I admire': 'This demonstrates resilience',

    // Buddy-like phrases
    'Hey!': 'Let\'s take a moment',
    'Don\'t worry': 'It\'s natural to',
    'I\'ve got you': 'Support is available',
    'I\'ve got your back': 'Resources can help',
    'We can': 'You may be able to',
    'Let\'s': 'You might consider',
  };

  static const List<String> _anthropomorphicPatterns = [
    r'Hi [^,]+, I ',
    r'Hey [^,]+, I ',
    r'Hello [^,]+, I ',
    r"I'm here",
    r'I feel like',
    r'In my opinion',
    r'Personally',
    r'From my perspective',
    r'As someone who',
    r"I've noticed",
    r"I've found",
    r'Trust me',
    r'Believe me',
  ];

  static String filterAnthropomorphicLanguage(String response) {
    String filtered = response;

    // Apply direct replacements
    _anthropomorphicReplacements.forEach((anthropomorphic, neutral) {
      filtered = filtered.replaceAll(
          RegExp(anthropomorphic, caseSensitive: false), neutral);
    });

    // Remove or replace pattern-based anthropomorphic language
    for (String pattern in _anthropomorphicPatterns) {
      filtered = filtered.replaceAll(RegExp(pattern, caseSensitive: false), '');
    }

    // Clean up any double spaces or awkward sentence starts
    filtered = filtered.replaceAll(RegExp(r'\s+'), ' ');
    filtered = filtered.replaceAll(RegExp(r'^\s*,'), '');
    filtered = filtered.trim();

    // Ensure sentences start properly after replacements
    if (filtered.isNotEmpty) {
      filtered = filtered[0].toUpperCase() + filtered.substring(1);
    }

    return filtered;
  }

  static String ensureEvidenceBasedLanguage(String response) {
    String processed = response;

    // If the response leads with evidence language but lacks any
    // supporting cues (citations, dates, or research terminology),
    // gently remove the automatic framing.
    final stripped = processed.trim();
    if (stripped.isEmpty) {
      return stripped;
    }
    processed = stripped;

    final hasCitation = RegExp(
      r'(https?://|doi|journal|meta-analysis|randomized|controlled trial|\b19\d{2}\b|\b20\d{2}\b|\bstudy\b)',
      caseSensitive: false,
    ).hasMatch(stripped);

    final leadingEvidencePattern = RegExp(
      r'^(research shows(?: that)?|studies indicate(?: that)?|evidence suggests(?: that)?|data shows(?: that)?|science indicates(?: that)?|findings suggest(?: that)?)\s+',
      caseSensitive: false,
    );

    if (!hasCitation && leadingEvidencePattern.hasMatch(stripped)) {
      final withoutPrefix =
          stripped.replaceFirst(leadingEvidencePattern, '').trimLeft();
      if (withoutPrefix.isNotEmpty) {
        processed = withoutPrefix[0].toUpperCase() + withoutPrefix.substring(1);
      } else {
        processed = withoutPrefix;
      }
    }

    return processed;
  }

  static String applyStarboundFraming(String response) {
    String framed = response;

    // Replace AI self-references with Starbound system references
    framed = framed.replaceAll(
        RegExp(r'I (provide|offer|give)', caseSensitive: false),
        'Starbound provides');
    framed = framed.replaceAll(
        RegExp(r'I can help', caseSensitive: false), 'Starbound can help');
    framed = framed.replaceAll(
        RegExp(r'I will', caseSensitive: false), 'Starbound will');

    return framed;
  }

  static String processResponse(String rawResponse) {
    String processed = rawResponse;

    // Apply all filters in sequence
    processed = filterAnthropomorphicLanguage(processed);
    processed = ensureEvidenceBasedLanguage(processed);
    processed = applyStarboundFraming(processed);

    return processed;
  }
}
