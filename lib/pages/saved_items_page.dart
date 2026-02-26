import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../models/saved_items_model.dart';
import '../models/health_resource_model.dart';
import '../providers/app_state.dart';

/// Saved Items Page - Two tabs: Resources and Conversations
class SavedItemsPage extends HookWidget {
  final VoidCallback onGoBack;

  const SavedItemsPage({Key? key, required this.onGoBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final savedResources = appState.savedResources;
    final savedConversations = appState.savedConversations;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1B2A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D1B2A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
            onPressed: onGoBack,
          ),
          title: const Text(
            'Saved Items',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          bottom: TabBar(
            indicatorColor: const Color(0xFF4ECDC4),
            indicatorWeight: 3,
            labelColor: const Color(0xFF4ECDC4),
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bookmark, size: 18),
                    const SizedBox(width: 8),
                    Text('Resources (${savedResources.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 18),
                    const SizedBox(width: 8),
                    Text('Conversations (${savedConversations.length})'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SavedResourcesTab(savedResources: savedResources),
            _SavedConversationsTab(savedConversations: savedConversations),
          ],
        ),
      ),
    );
  }
}

/// Saved Resources Tab
class _SavedResourcesTab extends StatelessWidget {
  final List<SavedResource> savedResources;

  const _SavedResourcesTab({required this.savedResources});

  @override
  Widget build(BuildContext context) {
    if (savedResources.isEmpty) {
      return _EmptyState(
        icon: Icons.bookmark_border,
        title: 'No saved resources yet',
        subtitle: 'Save health services from the Resources tab to access them quickly here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: savedResources.length,
      itemBuilder: (context, index) {
        final saved = savedResources[index];
        final resource = saved.resource;
        if (resource == null) {
          return const SizedBox.shrink(); // Skip if resource no longer exists
        }
        return _SavedResourceCard(saved: saved, resource: resource);
      },
    );
  }
}

/// Saved Conversations Tab
class _SavedConversationsTab extends StatelessWidget {
  final List<SavedConversation> savedConversations;

  const _SavedConversationsTab({required this.savedConversations});

  @override
  Widget build(BuildContext context) {
    if (savedConversations.isEmpty) {
      return _EmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'No saved conversations yet',
        subtitle: 'Save helpful health Q&A conversations to reference them later.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: savedConversations.length,
      itemBuilder: (context, index) {
        final conversation = savedConversations[index];
        return _SavedConversationCard(conversation: conversation);
      },
    );
  }
}

/// Empty state widget
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2838),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(
                icon,
                size: 48,
                color: Colors.white38,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Card for saved resource
class _SavedResourceCard extends StatelessWidget {
  final SavedResource saved;
  final HealthResource resource;

  const _SavedResourceCard({
    required this.saved,
    required this.resource,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTypeIcon(resource.type),
                    color: const Color(0xFF4ECDC4),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (resource.neighborhood != null)
                        Text(
                          resource.neighborhood!,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                // Remove button
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white38, size: 20),
                  onPressed: () => _confirmRemove(context, appState),
                  tooltip: 'Remove',
                ),
              ],
            ),
          ),

          // User notes (if any)
          if (saved.userNotes != null && saved.userNotes!.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, size: 16, color: Colors.white38),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      saved.userNotes!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Cost badge
          if (resource.costInfo != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _buildCostBadge(resource.costInfo!),
            ),

          // Quick actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (resource.phone != null)
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.phone,
                      label: 'Call',
                      onPressed: () => _launchPhone(resource.phone!),
                    ),
                  ),
                if (resource.phone != null && resource.address != null)
                  const SizedBox(width: 8),
                if (resource.address != null)
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.directions,
                      label: 'Directions',
                      onPressed: () => _launchDirections(resource.address!),
                    ),
                  ),
                if ((resource.phone != null || resource.address != null) && resource.website != null)
                  const SizedBox(width: 8),
                if (resource.website != null)
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.open_in_new,
                      label: 'Website',
                      onPressed: () => _launchUrl(resource.website!),
                    ),
                  ),
              ],
            ),
          ),

          // Saved date
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'Saved ${_formatDate(saved.savedAt)}',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostBadge(CostInfo costInfo) {
    String label;
    Color color;

    if (costInfo.isFreeService) {
      label = 'Free service';
      color = const Color(0xFF4ECDC4);
    } else if (costInfo.hasBulkBilling) {
      label = 'Bulk billing available';
      color = const Color(0xFF4ECDC4);
    } else if (costInfo.hasConcessionRates) {
      label = 'Concession rates';
      color = const Color(0xFFFFE66D);
    } else if (costInfo.costDescription != null) {
      label = costInfo.costDescription!;
      color = Colors.white54;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.attach_money, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(ResourceType type) {
    switch (type) {
      case ResourceType.clinic:
        return Icons.local_hospital;
      case ResourceType.hospital:
        return Icons.emergency;
      case ResourceType.pharmacy:
        return Icons.medication;
      case ResourceType.mentalHealth:
        return Icons.psychology;
      case ResourceType.urgentCare:
        return Icons.medical_services;
      case ResourceType.foodBank:
        return Icons.restaurant;
      case ResourceType.housing:
        return Icons.home;
      case ResourceType.transportation:
        return Icons.directions_bus;
      case ResourceType.community:
        return Icons.people;
      case ResourceType.substanceUse:
        return Icons.healing;
      case ResourceType.hotline:
        return Icons.phone_in_talk;
      case ResourceType.telehealth:
        return Icons.videocam;
      case ResourceType.dental:
        return Icons.sentiment_satisfied;
      case ResourceType.vision:
        return Icons.visibility;
      case ResourceType.womensHealth:
        return Icons.favorite;
      case ResourceType.youth:
        return Icons.child_care;
      case ResourceType.other:
        return Icons.help_outline;
    }
  }

  void _confirmRemove(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2838),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Remove saved resource?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Remove "${resource.name}" from your saved items?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              appState.unsaveResource(saved.resourceId);
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchDirections(String address) async {
    final encoded = Uri.encodeComponent(address);
    final uri = Uri.parse('https://maps.google.com/?q=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'today';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Card for saved conversation
class _SavedConversationCard extends StatefulWidget {
  final SavedConversation conversation;

  const _SavedConversationCard({required this.conversation});

  @override
  State<_SavedConversationCard> createState() => _SavedConversationCardState();
}

class _SavedConversationCardState extends State<_SavedConversationCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final conversation = widget.conversation;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with question
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9B59B6).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.question_answer,
                      color: Color(0xFF9B59B6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conversation.question,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: _isExpanded ? null : 2,
                          overflow: _isExpanded ? null : TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          conversation.timeAgo,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),
          ),

          // Key points (always visible if collapsed, full response if expanded)
          if (!_isExpanded && conversation.keyPoints.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  ...conversation.keyPoints.take(3).map((point) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(
                                color: Color(0xFF4ECDC4),
                                fontSize: 13,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                point,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),

          // Expanded: Full AI response
          if (_isExpanded) ...[
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Understanding
                  if (conversation.aiResponse.understanding.isNotEmpty) ...[
                    _SectionHeader(title: 'Understanding'),
                    const SizedBox(height: 8),
                    Text(
                      conversation.aiResponse.understanding,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Possible causes
                  if (conversation.aiResponse.possibleCauses.isNotEmpty) ...[
                    _SectionHeader(title: 'Possible Causes'),
                    const SizedBox(height: 8),
                    ...conversation.aiResponse.possibleCauses.map((cause) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.circle, size: 6, color: Color(0xFFFFE66D)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  cause,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],

                  // Immediate steps
                  if (conversation.aiResponse.immediateSteps.isNotEmpty) ...[
                    _SectionHeader(title: 'Recommended Steps'),
                    const SizedBox(height: 8),
                    ...conversation.aiResponse.immediateSteps.asMap().entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4ECDC4).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: const TextStyle(
                                      color: Color(0xFF4ECDC4),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],

                  // When to seek care
                  if (conversation.aiResponse.whenToSeekCare != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE74C3C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE74C3C).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.warning_amber,
                                color: Color(0xFFE74C3C),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'When to Seek Care: ${conversation.aiResponse.whenToSeekCare!.urgency}',
                                style: const TextStyle(
                                  color: Color(0xFFE74C3C),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (conversation.aiResponse.whenToSeekCare!.warningSignsToWatch.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ...conversation.aiResponse.whenToSeekCare!.warningSignsToWatch.map(
                              (sign) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '• ',
                                      style: TextStyle(color: Color(0xFFE74C3C)),
                                    ),
                                    Expanded(
                                      child: Text(
                                        sign,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Summary advice
                  if (conversation.aiResponse.summaryAdvice != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ECDC4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        conversation.aiResponse.summaryAdvice!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Linked resources
                  if (conversation.resources.isNotEmpty) ...[
                    _SectionHeader(title: 'Related Resources'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: conversation.resources.map((resource) {
                        return ActionChip(
                          avatar: Icon(
                            _getResourceIcon(resource.type),
                            size: 16,
                            color: const Color(0xFF4ECDC4),
                          ),
                          label: Text(
                            resource.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: const Color(0xFF0D1B2A),
                          side: const BorderSide(color: Color(0xFF4ECDC4)),
                          onPressed: () {
                            // Could navigate to resource or show details
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Tags
          if (conversation.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: conversation.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1B2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#$tag',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white54,
                  ),
                  onPressed: () => _copyToClipboard(context, conversation),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Remove'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent.withOpacity(0.7),
                  ),
                  onPressed: () => _confirmRemove(context, appState),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getResourceIcon(ResourceType type) {
    switch (type) {
      case ResourceType.clinic:
        return Icons.local_hospital;
      case ResourceType.hospital:
        return Icons.emergency;
      case ResourceType.pharmacy:
        return Icons.medication;
      case ResourceType.mentalHealth:
        return Icons.psychology;
      case ResourceType.urgentCare:
        return Icons.medical_services;
      case ResourceType.foodBank:
        return Icons.restaurant;
      case ResourceType.housing:
        return Icons.home;
      case ResourceType.transportation:
        return Icons.directions_bus;
      case ResourceType.community:
        return Icons.people;
      case ResourceType.substanceUse:
        return Icons.healing;
      case ResourceType.hotline:
        return Icons.phone_in_talk;
      case ResourceType.telehealth:
        return Icons.videocam;
      case ResourceType.dental:
        return Icons.sentiment_satisfied;
      case ResourceType.vision:
        return Icons.visibility;
      case ResourceType.womensHealth:
        return Icons.favorite;
      case ResourceType.youth:
        return Icons.child_care;
      case ResourceType.other:
        return Icons.help_outline;
    }
  }

  void _copyToClipboard(BuildContext context, SavedConversation conversation) {
    final buffer = StringBuffer();
    buffer.writeln('Q: ${conversation.question}');
    buffer.writeln();
    if (conversation.aiResponse.understanding.isNotEmpty) {
      buffer.writeln(conversation.aiResponse.understanding);
    }
    if (conversation.keyPoints.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Key points:');
      for (final point in conversation.keyPoints) {
        buffer.writeln('• $point');
      }
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _confirmRemove(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2838),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Remove saved conversation?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This conversation will be removed from your saved items.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              appState.unsaveConversation(widget.conversation.id);
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

/// Section header widget
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF4ECDC4),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

/// Quick action button
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0D1B2A),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: const Color(0xFF4ECDC4)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF4ECDC4),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
