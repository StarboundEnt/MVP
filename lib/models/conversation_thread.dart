import 'starbound_response.dart';

/// Represents a single exchange in a conversation
class ConversationExchange {
  final String id;
  final String question;
  final StarboundResponse response;
  final DateTime timestamp;
  final bool isFollowUp;
  final String? parentExchangeId;

  const ConversationExchange({
    required this.id,
    required this.question,
    required this.response,
    required this.timestamp,
    this.isFollowUp = false,
    this.parentExchangeId,
  });

  ConversationExchange copyWith({
    String? id,
    String? question,
    StarboundResponse? response,
    DateTime? timestamp,
    bool? isFollowUp,
    String? parentExchangeId,
  }) {
    return ConversationExchange(
      id: id ?? this.id,
      question: question ?? this.question,
      response: response ?? this.response,
      timestamp: timestamp ?? this.timestamp,
      isFollowUp: isFollowUp ?? this.isFollowUp,
      parentExchangeId: parentExchangeId ?? this.parentExchangeId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'response': response.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'isFollowUp': isFollowUp,
      'parentExchangeId': parentExchangeId,
    };
  }

  factory ConversationExchange.fromJson(Map<String, dynamic> json) {
    return ConversationExchange(
      id: json['id'],
      question: json['question'],
      response: StarboundResponse.fromJson(json['response']),
      timestamp: DateTime.parse(json['timestamp']),
      isFollowUp: json['isFollowUp'] ?? false,
      parentExchangeId: json['parentExchangeId'],
    );
  }
}

/// Represents a complete conversation thread
class ConversationThread {
  final String id;
  final String title;
  final List<ConversationExchange> exchanges;
  final DateTime createdAt;
  final DateTime lastActivity;
  final String? mainTopic;
  final Map<String, dynamic> context;

  const ConversationThread({
    required this.id,
    required this.title,
    required this.exchanges,
    required this.createdAt,
    required this.lastActivity,
    this.mainTopic,
    this.context = const {},
  });

  ConversationThread copyWith({
    String? id,
    String? title,
    List<ConversationExchange>? exchanges,
    DateTime? createdAt,
    DateTime? lastActivity,
    String? mainTopic,
    Map<String, dynamic>? context,
  }) {
    return ConversationThread(
      id: id ?? this.id,
      title: title ?? this.title,
      exchanges: exchanges ?? this.exchanges,
      createdAt: createdAt ?? this.createdAt,
      lastActivity: lastActivity ?? this.lastActivity,
      mainTopic: mainTopic ?? this.mainTopic,
      context: context ?? this.context,
    );
  }

  /// Add a new exchange to the thread
  ConversationThread addExchange(ConversationExchange exchange) {
    final updatedExchanges = List<ConversationExchange>.from(exchanges)..add(exchange);
    
    // Update context with latest information
    final updatedContext = Map<String, dynamic>.from(context);
    updatedContext['lastQuestion'] = exchange.question;
    updatedContext['lastResponse'] = exchange.response.overview;
    updatedContext['lastTheme'] = _extractTheme(exchange.question, exchange.response);
    updatedContext['exchangeCount'] = updatedExchanges.length;
    
    return copyWith(
      exchanges: updatedExchanges,
      lastActivity: exchange.timestamp,
      context: updatedContext,
    );
  }

  /// Get the last exchange in the conversation
  ConversationExchange? get lastExchange => exchanges.isNotEmpty ? exchanges.last : null;

  /// Get all follow-up suggestions based on conversation history
  List<String> getFollowUpSuggestions() {
    if (exchanges.isEmpty) return [];

    final lastExchange = exchanges.last;
    final suggestions = <String>[];

    // Generic follow-ups
    suggestions.addAll([
      "Tell me more about that",
      "What if that doesn't work?",
      "How long should this take?",
    ]);

    // Context-specific follow-ups based on last response
    final lastResponse = lastExchange.response;
    if (lastResponse.immediateSteps.isNotEmpty) {
      suggestions.add("How do I track my progress?");
      suggestions.add("What's the most important step?");
    }

    // Topic-specific follow-ups
    final topic = mainTopic ?? _extractTheme(lastExchange.question, lastExchange.response);
    switch (topic) {
      case 'sleep':
        suggestions.addAll([
          "What about morning routines?",
          "How to handle sleep disruptions?",
        ]);
        break;
      case 'energy':
        suggestions.addAll([
          "What foods boost energy?",
          "How to maintain energy levels?",
        ]);
        break;
      case 'stress':
        suggestions.addAll([
          "How to prevent this stress?",
          "What are quick stress relief techniques?",
        ]);
        break;
      case 'focus':
        suggestions.addAll([
          "How to eliminate distractions?",
          "What about longer focus sessions?",
        ]);
        break;
    }

    return suggestions.take(6).toList();
  }

  /// Build conversation context for AI
  String buildConversationContext() {
    if (exchanges.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('CONVERSATION HISTORY:');
    
    for (int i = 0; i < exchanges.length; i++) {
      final exchange = exchanges[i];
      buffer.writeln('Q${i + 1}: ${exchange.question}');
      buffer.writeln('A${i + 1}: ${exchange.response.overview}');
      if (exchange.response.immediateSteps.isNotEmpty) {
        buffer.writeln('Actions suggested: ${exchange.response.immediateSteps.length} steps');
      }
      buffer.writeln('');
    }

    buffer.writeln('CONTEXT:');
    buffer.writeln('- Main topic: ${mainTopic ?? "general wellness"}');
    buffer.writeln('- Exchange count: ${exchanges.length}');
    buffer.writeln('- Last theme: ${context['lastTheme'] ?? "general"}');
    
    return buffer.toString();
  }

  static String _extractTheme(String question, StarboundResponse response) {
    final text = '${question.toLowerCase()} ${response.overview.toLowerCase()}';
    
    if (text.contains(RegExp(r'\b(sleep|rest|insomnia|tired|exhausted)\b'))) return 'sleep';
    if (text.contains(RegExp(r'\b(energy|fatigue|alert|awake)\b'))) return 'energy';
    if (text.contains(RegExp(r'\b(stress|anxiety|overwhelm|pressure)\b'))) return 'stress';
    if (text.contains(RegExp(r'\b(focus|concentration|distract|attention)\b'))) return 'focus';
    if (text.contains(RegExp(r'\b(mood|feeling|sad|happy|emotion)\b'))) return 'mood';
    if (text.contains(RegExp(r'\b(water|hydration|drink)\b'))) return 'hydration';
    if (text.contains(RegExp(r'\b(exercise|movement|active|workout)\b'))) return 'movement';
    
    return 'general';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'exchanges': exchanges.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastActivity': lastActivity.toIso8601String(),
      'mainTopic': mainTopic,
      'context': context,
    };
  }

  factory ConversationThread.fromJson(Map<String, dynamic> json) {
    return ConversationThread(
      id: json['id'],
      title: json['title'],
      exchanges: (json['exchanges'] as List)
          .map((e) => ConversationExchange.fromJson(e))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      lastActivity: DateTime.parse(json['lastActivity']),
      mainTopic: json['mainTopic'],
      context: Map<String, dynamic>.from(json['context'] ?? {}),
    );
  }
}