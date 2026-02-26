import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/error_service.dart';
import 'selective_widgets.dart';

class SyncStatusWidget extends StatelessWidget {
  final bool showCompact;
  final bool showOnlyWhenSyncing;
  
  const SyncStatusWidget({
    Key? key,
    this.showCompact = false,
    this.showOnlyWhenSyncing = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Performance optimization: Use selective sync status listening
    return SelectiveSyncStatus(
      builder: (context, hasPendingSync) {
        return AppStateSelector<Map<String, dynamic>>(
          selector: (appState) => appState.syncStatus,
          builder: (context, syncStatus, child) {
            final isSyncing = syncStatus['isSyncing'] as bool? ?? false;
            final pendingCount = syncStatus['pendingCount'] as int? ?? 0;
            final hasPending = syncStatus['hasPendingActions'] as bool? ?? false;
            
            // Don't show anything if no pending sync and set to only show when syncing
            if (showOnlyWhenSyncing && !isSyncing && !hasPending) {
              return const SizedBox.shrink();
            }
            
            if (showCompact) {
              return _buildCompactStatus(context, isSyncing, pendingCount, hasPending);
            } else {
              return _buildFullStatus(context, isSyncing, pendingCount, hasPending);
            }
          },
        );
      },
    );
  }
  
  Widget _buildCompactStatus(
    BuildContext context,
    bool isSyncing,
    int pendingCount,
    bool hasPending,
  ) {
    if (isSyncing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF00F5D4).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00F5D4).withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF00F5D4)),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Syncing...',
              style: TextStyle(
                color: const Color(0xFF00F5D4),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else if (hasPending) {
      return GestureDetector(
        onTap: () => _showSyncDialog(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sync_problem,
                color: Colors.orange,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                '$pendingCount',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
  
  Widget _buildFullStatus(
    BuildContext context,
    bool isSyncing,
    int pendingCount,
    bool hasPending,
  ) {
    String statusText;
    Color statusColor;
    IconData statusIcon;
    VoidCallback? onTap;
    
    if (isSyncing) {
      statusText = 'Syncing your data...';
      statusColor = const Color(0xFF00F5D4);
      statusIcon = Icons.sync;
    } else if (hasPending) {
      statusText = '$pendingCount item${pendingCount != 1 ? 's' : ''} waiting to sync';
      statusColor = Colors.orange;
      statusIcon = Icons.sync_problem;
      onTap = () => _showSyncDialog(context);
    } else {
      statusText = 'All data synced';
      statusColor = const Color(0xFF27AE60);
      statusIcon = Icons.check_circle;
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSyncing)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              )
            else
              Icon(statusIcon, color: statusColor, size: 16),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                color: statusColor,
                size: 10,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _showSyncDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F0150),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.sync, color: const Color(0xFF00F5D4)),
            const SizedBox(width: 8),
            Text(
              'Sync Status',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Some of your data hasn\'t been synced to the cloud yet.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your data is safe locally. We\'ll sync it when possible.',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Consumer<AppState>(
              builder: (context, appState, child) {
                return Row(
                  children: [
                    Icon(Icons.queue, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${appState.pendingSyncCount} items pending',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final appState = context.read<AppState>();
              
              // Show loading feedback
              ErrorService.showLoadingFeedback(context, 'Syncing data...');
              
              try {
                final success = await appState.syncNow();
                if (success) {
                  ErrorService.showSuccessFeedback(context, 'All data synced successfully!');
                } else {
                  ErrorService.showSyncFeedback(
                    context, 
                    'Sync failed. Will retry automatically.',
                    isError: true,
                  );
                }
              } catch (e) {
                ErrorService.showSyncFeedback(
                  context,
                  'Sync failed: ${e.toString()}',
                  isError: true,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F5D4),
              foregroundColor: const Color(0xFF1F0150),
            ),
            child: Text('Sync Now'),
          ),
        ],
      ),
    );
  }
}

// Sync status indicator for app bar
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (!appState.hasPendingSync && !appState.syncStatus['isSyncing']) {
          return const SizedBox.shrink();
        }
        
        return Container(
          margin: const EdgeInsets.only(right: 8),
          child: SyncStatusWidget(showCompact: true, showOnlyWhenSyncing: true),
        );
      },
    );
  }
}

// Last sync time widget
class LastSyncTimeWidget extends StatelessWidget {
  const LastSyncTimeWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return FutureBuilder<DateTime?>(
          future: appState.getLastSyncTime(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return const SizedBox.shrink();
            }
            
            final lastSync = snapshot.data!;
            final now = DateTime.now();
            final difference = now.difference(lastSync);
            
            String timeAgo;
            if (difference.inMinutes < 1) {
              timeAgo = 'Just now';
            } else if (difference.inHours < 1) {
              timeAgo = '${difference.inMinutes}m ago';
            } else if (difference.inDays < 1) {
              timeAgo = '${difference.inHours}h ago';
            } else {
              timeAgo = '${difference.inDays}d ago';
            }
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    color: Colors.white60,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Last sync: $timeAgo',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}