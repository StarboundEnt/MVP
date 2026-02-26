import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/backup_service.dart';

/// Screen to scan QR code or paste backup data to restore
class QRRestoreScreen extends StatefulWidget {
  const QRRestoreScreen({Key? key}) : super(key: key);

  @override
  State<QRRestoreScreen> createState() => _QRRestoreScreenState();
}

class _QRRestoreScreenState extends State<QRRestoreScreen>
    with SingleTickerProviderStateMixin {
  final BackupService _backupService = BackupService();
  final TextEditingController _passphraseController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();

  late TabController _tabController;
  MobileScannerController? _scannerController;

  RestoreResult? _previewResult;
  bool _isProcessing = false;
  bool _showPassphrase = false;
  bool _useCustomPassphrase = false;
  String? _scannedData;
  RestoreMode _selectedMode = RestoreMode.replaceAll;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scannerController?.dispose();
    _passphraseController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  void _onQRDetected(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final data = barcodes.first.rawValue;
    if (data == null || data.isEmpty) return;

    // Pause scanning
    _scannerController?.stop();

    setState(() {
      _scannedData = data;
    });

    _previewBackup(data);
  }

  Future<void> _previewBackup(String data) async {
    setState(() => _isProcessing = true);

    try {
      final passphrase =
          _useCustomPassphrase ? _passphraseController.text.trim() : null;

      final result = await _backupService.parseBackup(
        data,
        passphrase: passphrase,
        mode: RestoreMode.preview,
      );

      setState(() {
        _previewResult = result;
        _isProcessing = false;
      });

      if (!result.success) {
        _showError(result.error ?? 'Failed to parse backup');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Error parsing backup: $e');
    }
  }

  Future<void> _performRestore() async {
    if (_scannedData == null && _dataController.text.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final passphrase =
          _useCustomPassphrase ? _passphraseController.text.trim() : null;
      final data = _scannedData ?? _dataController.text.trim();

      final result = await _backupService.restoreBackup(
        appState,
        data,
        passphrase: passphrase,
        mode: _selectedMode,
      );

      setState(() => _isProcessing = false);

      if (result.success) {
        if (mounted) {
          _showSuccess();
        }
      } else {
        _showError(result.error ?? 'Failed to restore backup');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Error restoring backup: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE74C3C),
      ),
    );
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2838),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF2ECC71),
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Restore Complete!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your data has been restored successfully.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to settings
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ECC71),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  void _resetScanner() {
    setState(() {
      _scannedData = null;
      _previewResult = null;
    });
    _scannerController?.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Restore Backup',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF4ECDC4),
          labelColor: const Color(0xFF4ECDC4),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(
              icon: Icon(Icons.qr_code_scanner, size: 20),
              text: 'Scan QR',
            ),
            Tab(
              icon: Icon(Icons.paste, size: 20),
              text: 'Paste Data',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScannerTab(),
          _buildPasteTab(),
        ],
      ),
    );
  }

  Widget _buildScannerTab() {
    if (_previewResult != null) {
      return _buildPreviewContent(_scannedData!);
    }

    return Column(
      children: [
        // Scanner view
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: _onQRDetected,
              ),
              // Scanning overlay
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF4ECDC4),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              // Processing indicator
              if (_isProcessing)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4ECDC4),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Instructions
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Point your camera at the backup QR code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildPassphraseField(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasteTab() {
    if (_previewResult != null && _dataController.text.isNotEmpty) {
      return _buildPreviewContent(_dataController.text.trim());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Paste your backup data',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You can paste the backup code that was copied or shared from another device.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          // Data input
          TextField(
            controller: _dataController,
            maxLines: 6,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              hintText: 'Paste backup data here...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF1B2838),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste, color: Colors.white54),
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    _dataController.text = data!.text!;
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildPassphraseField(),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _dataController.text.isNotEmpty && !_isProcessing
                ? () => _previewBackup(_dataController.text.trim())
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ECDC4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              disabledBackgroundColor: const Color(0xFF4ECDC4).withOpacity(0.5),
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Preview Backup',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassphraseField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                color: _useCustomPassphrase
                    ? const Color(0xFFFFDA3E)
                    : Colors.white54,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Backup has passphrase',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Switch(
                value: _useCustomPassphrase,
                onChanged: (value) {
                  setState(() => _useCustomPassphrase = value);
                },
                activeColor: const Color(0xFFFFDA3E),
              ),
            ],
          ),
          if (_useCustomPassphrase) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _passphraseController,
              obscureText: !_showPassphrase,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter the passphrase',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassphrase ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white54,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _showPassphrase = !_showPassphrase);
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewContent(String data) {
    final result = _previewResult!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!result.success) ...[
            _buildErrorCard(result.error ?? 'Failed to parse backup'),
          ] else ...[
            _buildBackupPreviewCard(result.data!),
            const SizedBox(height: 24),
            _buildRestoreModeSelector(),
            const SizedBox(height: 24),
            _buildRestoreButton(),
          ],
          const SizedBox(height: 16),
          TextButton(
            onPressed: _resetScanner,
            child: const Text(
              'Scan different QR code',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupPreviewCard(BackupData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF2ECC71),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Valid backup found',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Ready to restore',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),

          // Backup details
          _buildDetailRow(
            'Created',
            _formatDate(data.createdAt),
          ),
          if (data.deviceInfo != null)
            _buildDetailRow('Device', data.deviceInfo!),
          _buildDetailRow('Version', data.version),

          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),

          // Content summary
          const Text(
            'Content',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),

          if (data.profile != null)
            _buildContentRow(
              Icons.person_outline,
              'Profile: ${data.profile!.userName}',
            ),
          if (data.savedResources.isNotEmpty)
            _buildContentRow(
              Icons.bookmark_outline,
              '${data.savedResources.length} saved resources',
            ),
          if (data.savedConversations.isNotEmpty)
            _buildContentRow(
              Icons.chat_bubble_outline,
              '${data.savedConversations.length} saved conversations',
            ),
          if (data.journalEntries.isNotEmpty)
            _buildContentRow(
              Icons.calendar_today_outlined,
              '${data.journalEntries.length} journal entries',
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4ECDC4), size: 18),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestoreModeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Restore mode',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildModeOption(
            RestoreMode.replaceAll,
            'Replace all',
            'Delete current data and restore backup',
            const Color(0xFFE74C3C),
          ),
          const SizedBox(height: 8),
          _buildModeOption(
            RestoreMode.merge,
            'Merge',
            'Keep current data and add new items',
            const Color(0xFF2ECC71),
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption(
    RestoreMode mode,
    String title,
    String description,
    Color color,
  ) {
    final isSelected = _selectedMode == mode;

    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? color : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? color : Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestoreButton() {
    return ElevatedButton(
      onPressed: _isProcessing ? null : _performRestore,
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedMode == RestoreMode.replaceAll
            ? const Color(0xFFE74C3C)
            : const Color(0xFF2ECC71),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: _isProcessing
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _selectedMode == RestoreMode.replaceAll
                      ? Icons.restore
                      : Icons.merge,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedMode == RestoreMode.replaceAll
                      ? 'Replace & Restore'
                      : 'Merge & Restore',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE74C3C).withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE74C3C).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFE74C3C),
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'Invalid backup',
            style: TextStyle(
              color: Color(0xFFE74C3C),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'If this backup was created with a passphrase, make sure to enter it above.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
